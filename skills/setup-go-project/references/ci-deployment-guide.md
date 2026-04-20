# CI/CD & Deployment Configuration

Every Futu FRPC project needs three artifacts for CI pipeline + deployment:

1. **`deploy.yaml`** — supervisor config + liveness probe
2. **CI packaging paths** — what to include in the deployable archive
3. **Makefile `build` target** — correct flags to avoid CI OOM

---

## 1. `deploy.yaml` (project root)

Describes how the deployment platform runs the service. Copy from `fds_explore_service/deploy.yaml` as the simplest template; `fds_backend/deploy.yaml` adds an `after_up` hook if you need a post-start health check script.

```yaml
attrs:
  is_background_program: 0
foreground_program:
- program_name: <service_name>                                  # Must match binary name + artifact repo name
  supervisor_conf: |
    program_name=<service_name>
    command=#INSTALL_PATH/bin/<service_name> -config #INSTALL_PATH/conf/conf.toml
    stopsignal=TERM
    directory=#INSTALL_PATH
    numprocs=1
    process_name=%(program_name)s
    startsecs=3
    startretries=3
    autorestart=true
    exitcodes=0
    stopwaitsecs=45
    environment=LANG="en_US.UTF-8",LC_ALL="en_US.UTF-8"
    stopasgroup=true
    killasgroup=true
    user = ops
    autostart = false
    stdout_logfile = /data/log/#PKG_NAME/%(program_name)s_stdout.log
    stdout_logfile_maxbytes = 100MB
    stdout_logfile_backups = 10
    stdout_events_enabled = false
    stderr_logfile = /data/log/#PKG_NAME/%(program_name)s_stderr.log
    stderr_logfile_maxbytes = 100MB
    stderr_logfile_backups = 10
    stderr_capture_maxbytes = 1MB
liveness:
- failure_action: alert
  initial_delay_seconds: 5
  is_enabled: true
  liveness_type: tcp
  period_seconds: 10
  probe_type: liveness
  tcp_port: <srpc_port>                                         # ← [frpc.server.srpc].port (NOT http port)
  timeout_seconds: 3
- failure_action: alert
  http_url: ''
  initial_delay_seconds: 5
  is_enabled: false
  liveness_type: http
  probe_type: startup
  timeout_seconds: 3
```

**Field rules**:

| Field | Rule |
|---|---|
| `program_name` | = binary name = Makefile `PROJECT_NAME` = artifact repo name |
| `command` | Use `-config` (single hyphen), not `--config`, to align with fds_* projects |
| `user = ops` | Futu standard runtime user — don't change |
| `tcp_port` | Must be the **srpc port** from `[frpc.server.srpc]`, not the http port |
| `#INSTALL_PATH` / `#PKG_NAME` | Placeholders replaced by deployment platform; write literally |

---

## 2. CI Packaging Paths

In the CI platform's "packaging rules" section:

| Setting | Value |
|---|---|
| Package paths | `conf`, `bin`, `deploy.yaml` |
| Exclude paths | `.git/**` |
| Include untracked | No |

**Optional additions**:
- `locale` — only if i18n uses file-based resources (FRPC's built-in i18n module). Skip if i18n goes through DB.
- `migrations` — only if the service runs migrations on startup. Skip if DDL is applied manually.

---

## 3. CI Build Script

```bash
# gomod/gocache caching for faster subsequent CI runs
export GOPATH=${CI_PROJECT_DIR}/.go
export GOMODCACHE=${GOPATH}/pkg/mod
export GOCACHE=${CI_PROJECT_DIR}/.ci_cache

make build
```

The three `export` lines are **not optional**:

- `GOPATH` → CI workdir → allows `.gitlab-ci.yml cache.paths` to persist modules across builds
- `GOMODCACHE` → avoids re-downloading `*.futunn.com` private modules every run (slow, flaky)
- `GOCACHE` → Go build cache → incremental compilations are many times faster

Also ensure `.gitlab-ci.yml` has:

```yaml
cache:
  paths:
    - .go/pkg/mod
    - .ci_cache
```

Otherwise the `export` lines set a destination that CI never persists.

---

## 4. Makefile `build` Target

The default FRPC scaffold's `build` target has no `-p` limit. Override to:

```makefile
build: dep fmt ## Build frpc project
	@echo "go build..."
	@go build -p 2 -buildmode=default -o bin/${PROJECT_NAME} cmd/main.go
	@chmod +x bin/${PROJECT_NAME}
```

**Why each flag**:

| Flag | Reason |
|---|---|
| `-p 2` | Caps compilation parallelism at 2. Halves peak memory during linking. Essential because FRPC's `pkg/thirdparty/db/gorm` does `_ "gorm.io/driver/{mysql,postgres,clickhouse,sqlserver}"` blank imports — all drivers compile into the binary even if you only use one. |
| Drop `-v` | Saves log verbosity for progress lines; Go still prints `# package` on errors. |

### ⚠️ Do NOT set `CGO_ENABLED=0`

Even though your own code has zero `import "C"`, FRPC's transitive dependency chain needs cgo on Linux:

```
frpc → ftrace-instrumentation/frpc/rpc
     → gitlab.futunn.com/golang/metric
     → gitlab.futunn.com/golang/monitor
```

`monitor` defines `Inc`/`Set` functions across three files with Linux-specific cgo:
- `monitor_linux.go` — `#cgo CFLAGS: -I./clib/oi`, defines exported `Inc`/`Set`
- `monitor.go` — has `//+build windows darwin` (excluded on Linux)
- `monitor_common.go` — only lowercase helper functions

With `CGO_ENABLED=0` on a Linux CI runner, both the cgo file and the windows/darwin file get excluded → `Inc`/`Set` are undefined → `metric@v0.0.12/monitor.go:45,46,57` fails to compile.

This is invisible on macOS (where `monitor.go` compiles fine without cgo), so you can pass local builds and still fail CI. **Keep CGO enabled; only use `-p 2` to control memory.**

---

## 5. Diagnosing CI Build OOM

**Symptom**: CI log shows only `make: *** [Makefile:XX: build] Error 1` with **no compiler error output** (no `# package\n file.go:XX: error` block). This is the fingerprint of the Go compiler being SIGKILLed by the OS — almost always OOM, because a compile error would produce explicit output.

**Verify dependency bloat**:

```bash
go mod why github.com/ClickHouse/clickhouse-go/v2
# If shown: dependency chain goes through frpc/pkg/thirdparty/db/gorm → gorm.io/driver/clickhouse
```

This is framework-level: FRPC itself blank-imports every gorm driver to support "configure and go" DB usage. Project-level `go.mod exclude` will break FRPC's compilation, so the fix must come from build flags.

**Fix order**:
1. Apply §4's `CGO_ENABLED=0 -p 2` recipe
2. If still OOM, ask ops to raise the CI runner's memory limit
3. As a last resort, `go build -p 1` (single-process) but builds will be painfully slow

---

## Checklist

- [ ] `deploy.yaml` in project root, `program_name` aligns with artifact name
- [ ] `tcp_port` in liveness section matches `[frpc.server.srpc].port` in `conf.toml`
- [ ] CI packaging paths: `conf`, `bin`, `deploy.yaml`, excluding `.git/**`
- [ ] CI script exports `GOPATH` / `GOMODCACHE` / `GOCACHE` before `make build`
- [ ] `.gitlab-ci.yml` `cache.paths` includes `.go/pkg/mod` and `.ci_cache`
- [ ] Makefile `build` uses `go build -p 2 ...` (keep CGO default on; do NOT set `CGO_ENABLED=0`)
