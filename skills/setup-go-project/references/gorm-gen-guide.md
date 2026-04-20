# GORM Gen Configuration & Usage Guide

GORM Gen is the official code generation tool for GORM. It generates type-safe DAO APIs from database schemas, eliminating hand-written CRUD code. At Futu, it replaces the FRPC scaffold's basic model/dao generation with more flexible, 100% type-safe APIs.

## Installation

```bash
go get -u gorm.io/gen
```

## Project Structure

GORM Gen outputs go into two directories:

```
gorm/
  └── main.go              # Gen configuration & execution entry
internal/app/
  ├── store/               # Generated DAO code (query builders)
  │   ├── gen.go
  │   └── {table}.gen.go
  └── model/
      └── db/              # Generated model structs
          └── {table}_model.go
```

Within FRPC projects, the `store/` directory lives alongside `model/` under `internal/app/`. The `gorm/` directory is at project root as a standalone code-gen entry point (similar to how `cmd/` holds `main.go`).

---

## Configuration Template

**Hard rule: never hardcode DSN / username / password** in `gorm/main.go`. Always read from `conf/conf.toml` via FRPC's `pkg/conf` package. Keep `--dsn` as an override flag for edge cases (prod DB, other libraries, temporary experiments).

Create `gorm/main.go`:

```go
package main

import (
    "flag"
    "fmt"
    "os"
    "strings"

    "gitlab.futunn.com/infra/frpc/pkg/conf"
    "gorm.io/driver/mysql"
    "gorm.io/gen"
    "gorm.io/gorm"
)

type mysqlConfig struct {
    Username  string `toml:"username"`
    Password  string `toml:"password"`
    Address   string `toml:"address"`
    DBName    string `toml:"db_name"`
    Collation string `toml:"collation"`
}

func main() {
    configPath := flag.String("config", "conf/conf.toml", "Path to frpc conf.toml")
    dsnOverride := flag.String("dsn", "", "Override DSN (bypasses conf.toml when set)")
    printDSN := flag.Bool("print-dsn", false, "Print resolved DSN and exit (debug)")
    flag.Parse()

    dsn := *dsnOverride
    if dsn == "" {
        built, err := buildDSN(*configPath)
        if err != nil {
            fmt.Fprintf(os.Stderr, "failed to build DSN: %v\n", err)
            os.Exit(1)
        }
        dsn = built
    }
    if *printDSN {
        fmt.Println(dsn)
        return
    }

    db, err := gorm.Open(mysql.Open(dsn), &gorm.Config{})
    if err != nil {
        fmt.Fprintf(os.Stderr, "failed to connect: %v\n", err)
        os.Exit(1)
    }

    g := gen.NewGenerator(gen.Config{
        OutPath:           "./internal/app/store",
        ModelPkgPath:      "./internal/app/model/db",
        Mode:              gen.WithDefaultQuery | gen.WithQueryInterface,
        FieldNullable:     true,
        FieldSignable:     true,
        FieldWithIndexTag: true,
        FieldWithTypeTag:  true,
    })
    g.UseDB(db)

    g.ApplyBasic(
        g.GenerateModel("table_name_1"),
        g.GenerateModel("table_name_2"),
    )
    g.Execute()
}

// buildDSN reads [frpc.mysql.<instance>] from conf.toml using FRPC's config API.
// Replace `<instance>` with your actual instance name (e.g. "metrics", "da_fds").
func buildDSN(path string) (string, error) {
    cfg := conf.NewConfig()
    cfg.SetIgnoreUnused(true) // skip timeout/pool fields not needed for DSN
    if err := cfg.LoadFile(path); err != nil {
        return "", fmt.Errorf("load config: %w", err)
    }

    var m mysqlConfig
    if err := cfg.Unmarshal("frpc.mysql.<instance>", &m); err != nil {
        return "", fmt.Errorf("unmarshal [frpc.mysql.<instance>]: %w", err)
    }
    if m.Username == "" || m.Password == "" || m.Address == "" || m.DBName == "" {
        return "", fmt.Errorf("missing required mysql fields")
    }
    if m.Collation == "" {
        m.Collation = "utf8mb4_bin"
    }

    // FRPC address prefixes: test_{ip:port}, cmlb_{id}, fns://...
    // Only test_{ip:port} is directly usable by gorm; others need --dsn override.
    addr := strings.TrimPrefix(m.Address, "test_")
    if strings.HasPrefix(addr, "cmlb_") || strings.Contains(addr, "://") {
        return "", fmt.Errorf("address %q not directly usable; pass --dsn", m.Address)
    }

    return fmt.Sprintf(
        "%s:%s@tcp(%s)/%s?charset=utf8mb4&collation=%s&parseTime=True&loc=Local",
        m.Username, m.Password, addr, m.DBName, m.Collation,
    ), nil
}
```

### Why This Pattern

| Anti-pattern | Problem | Fix |
|---|---|---|
| Hardcode DSN constant | Password rotates, tool drifts from reality | Read from conf.toml |
| Only `--dsn` flag, no conf fallback | Every run requires passing password; easy to leak to shell history | Default = conf.toml, `--dsn` as override |
| Use `pelletier/go-toml` directly | Redundant; FRPC already pulls it transitively via `pkg/conf` | Use `conf.NewConfig()` + `LoadFile` + `Unmarshal` |
| Omit `SetIgnoreUnused(true)` | Strict mode fails on `dial_timeout`/`max_idle_conns` etc. | Always call `SetIgnoreUnused(true)` for partial struct reads |

### Running

```bash
# Default: reads conf/conf.toml [frpc.mysql.<instance>]
go run gorm/main.go

# Override DSN (for prod DB, other libraries)
go run gorm/main.go --dsn "user:pass@tcp(10.1.2.3:3306)/mydb?..."

# Debug: print resolved DSN without running gen
go run gorm/main.go --print-dsn
```

### Config Options Explained

| Option | Effect |
|--------|--------|
| `FieldNullable: true` | Nullable DB fields become pointer types in Go (`*string` instead of `string`) |
| `FieldSignable: true` | `unsigned` DB columns use `uint` types in Go |
| `FieldWithIndexTag: true` | Model structs include `gorm:"index:..."` tags from DB indexes |
| `FieldWithTypeTag: true` | Model structs include `gorm:"type:..."` tags from DB column types |
| `gen.WithDefaultQuery` | Generates a default global `Query` variable for quick access |
| `gen.WithQueryInterface` | Generates query interface types for mocking in tests |
| `gen.WithoutContext` | Generates `WithoutContext` mode — cleaner code when ctx not needed |

### Mode Selection

The screenshots show both `WithContext` and `WithoutContext` patterns. In Futu FRPC projects, **`WithoutContext` is commonly used** for cleaner code. If your project uses `WithContext(ctx)` everywhere, omit the `gen.WithoutContext` flag.

```go
// WithContext mode (explicit ctx everywhere)
query.WithContext(ctx).User.Where(...)

// WithoutContext mode (cleaner, ctx passed at creation)
query.User.Where(...)
```

---

## Running GORM Gen

```bash
go run gorm/main.go
```

This generates:
- Model structs in `internal/app/store/model/` (or `ModelPkgPath`)
- DAO query builders in `internal/app/store/` (or `OutPath`)

---

## Integration with FRPC

In FRPC projects, you cannot use `g.UseDB(db)` with a direct GORM connection for production DB access — FRPC manages its own DB connection pool with lifecycle tied to `application.Run`. 

**For code generation only** (the `gorm/main.go` entry), a direct connection is fine since it runs offline.

**For runtime DB access**, use FRPC's `application.Run` to get the managed DB connection, then use the generated DAO code:

```go
// At runtime, within FRPC lifecycle:
// 1. Get DB via FRPC's managed connection
// 2. Use generated query builders with that connection
```

Refer to FRPC official docs for `application.Run` DB connection management.

---

## Example: Full Integration

Given this SQL:

```sql
CREATE TABLE cleaning_duty_robot.distributed_lock (
    id          bigint unsigned auto_increment primary key,
    name        varchar(32) unique                          not null,
    ip          int unsigned                                not null,
    expiry      timestamp                                   not null,
    created_at  timestamp default current_timestamp         not null,
    updated_at  timestamp default current_timestamp 
                on update current_timestamp                 not null
) character set = utf8mb4
  collate = utf8mb4_bin comment '分布式锁表';
```

The GORM Gen config:

```go
g.ApplyBasic(g.GenerateModel("distributed_lock"))
```

Generates a model like:

```go
// internal/app/store/model/distributed_lock.gen.go
type DistributedLock struct {
    ID        uint64     `gorm:"column:id;primaryKey;autoIncrement:true" json:"id"`
    Name      string     `gorm:"column:name;type:varchar(32);uniqueIndex" json:"name"`
    IP        uint32     `gorm:"column:ip;type:int unsigned;not null" json:"ip"`
    Expiry    time.Time  `gorm:"column:expiry;type:timestamp;not null" json:"expiry"`
    CreatedAt time.Time  `gorm:"column:created_at;type:timestamp;default:current_timestamp" json:"created_at"`
    UpdatedAt time.Time  `gorm:"column:updated_at;type:timestamp;default:current_timestamp on update current_timestamp" json:"updated_at"`
}
```

And a query builder in `internal/app/store/distributed_lock.gen.go` with type-safe CRUD methods.

---

## Tips

- Run `go run gorm/main.go` every time the DB schema changes to regenerate models
- Generated files have `.gen.go` suffix — never manually edit these
- For custom query methods, define interfaces and use `g.ApplyInterface()` instead of modifying generated code
- Keep `gorm/main.go` as a standalone tool — it's not part of the service runtime
