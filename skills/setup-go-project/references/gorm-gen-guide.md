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

Create `gorm/main.go`:

```go
package main

import (
    "gorm.io/gen"
    // import your DB driver
)

func main() {
    g := gen.NewGenerator(gen.Config{
        // DAO output path
        OutPath:      "./internal/app/store",
        // Model output path
        ModelPkgPath: "./store/model",

        // Recommended settings
        FieldNullable:     true,  // Use pointer types for nullable fields
        FieldSignable:     true,  // Use unsigned int types where applicable
        FieldWithIndexTag: true,  // Generate index tags from DB
        FieldWithTypeTag:  true,  // Generate type tags from DB

        // Query interface mode
        Mode: gen.WithDefaultQuery |   // Generate default query variable
              gen.WithQueryInterface | // Generate query interface
              gen.WithoutContext,       // Generate WithoutContext mode
    })

    // Connect to database
    // db, _ := gorm.Open(mysql.Open("root:password@tcp(127.0.0.1:3306)/dbname?charset=utf8mb4&parseTime=True"))
    g.UseDB(db)

    // Generate basic CRUD for tables
    g.ApplyBasic(
        g.GenerateModel("table_name_1"),
        g.GenerateModel("table_name_2"),
    )

    // Optional: Apply custom query interfaces
    // g.ApplyInterface(func(model.Querier){}, model.User{})

    g.Execute()
}
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
