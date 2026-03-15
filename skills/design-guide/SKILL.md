---
name: design-guide
description: "Contextual design pattern selection guide. Use when making architecture decisions, choosing design patterns, reviewing code structure, or designing new modules. Covers GoF patterns, data architecture patterns (CQRS, Event Sourcing, Saga), Repository Pattern, frontend patterns, and anti-patterns. Trigger words: design pattern, architecture decision, how to structure, which pattern, 设计模式, 架构设计"
user-invocable: true
---

# Design Pattern Selection Guide

Help choose the right design pattern for the current scenario.

## Arguments

$ARGUMENTS

If no arguments provided, ask:
1. What module/feature is being designed?
2. What problem needs solving? (extensibility, decoupling, state management, data flow, etc.)
3. What's the expected scale and complexity?

---

## Core Principle

> **Pattern is a means, not an end.** Only apply a pattern when the problem it solves actually exists in your codebase. The simplest correct solution is the best solution.

## Decision Flow

Before suggesting any pattern, evaluate in order:

1. **Can a plain function/module solve this?** → If yes, stop here
2. **Is the complexity justified by current requirements (not hypothetical future)?** → If no, use simpler approach
3. **Will the team understand and maintain this pattern?** → If uncertain, prefer explicit over clever
4. **Does Dorian's CLAUDE.md already mandate an approach?** → Invariants (layered architecture, SOLID, no-any) always apply on top of pattern choices

---

## Pattern Reference

### Creational Patterns — "How to create objects"

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **Factory Method** | Creation logic varies by type; caller shouldn't know concrete class | Only 1-2 types, simple `new` suffices |
| **Abstract Factory** | Families of related objects that must be used together (e.g., UI theme system, cross-platform adapters) | Single product family, no variation needed |
| **Builder** | Complex object with many optional parameters; step-by-step construction | Object is simple (< 4 params), constructor suffices |
| **Singleton** | Truly global shared resource (DB connection pool, config registry) | **Almost always wrong in frontend.** Prefer DI/Context to provide instances |

### Structural Patterns — "How to compose objects"

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **Adapter** | Integrating third-party API with incompatible interface | You control both sides — just change the interface |
| **Decorator** | Adding cross-cutting behavior without modifying target (logging, caching, retry, auth) | Deep decorator chains (> 3 levels) — use middleware pipeline instead |
| **Facade** | Simplifying complex subsystem with a unified API (e.g., SDK wrapper, service aggregation) | Subsystem is already simple |
| **Proxy** | Lazy loading, access control, caching transparent to caller | Adds indirection without clear benefit |
| **Composite** | Tree structures (file system, org chart, menu, AST) | Flat list — use array |

### Behavioral Patterns — "How objects interact"

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **Strategy** | Algorithm/behavior varies at runtime; replaces if-else/switch chains with 3+ branches | 1-2 branches — if-else is clearer and more readable |
| **Observer / EventEmitter** | Decoupled 1:N notifications (state change → multiple UI updates) | Debugging event chains becomes impossible; prefer explicit calls for < 3 listeners |
| **Command** | Undo/redo, operation queue, macro recording, audit trail | Simple CRUD with no undo/history requirement |
| **State** | Object behavior changes with internal state; complex state transitions (order lifecycle, workflow engine) | ≤ 3 states with no complex transitions — switch/if is fine |
| **Chain of Responsibility** | Pipeline processing (middleware, validators, interceptors, approval chains) | Fixed processing order with no need for dynamic chain |
| **Template Method** | Shared algorithm skeleton with customizable steps (e.g., data export with different formats) | Composition via functions or hooks achieves the same goal |
| **Mediator** | Complex many-to-many interactions between objects (chat room, form field dependencies) | Simple direct communication between 2-3 objects |

### Data Architecture Patterns — "How to structure data flow"

| Pattern | Use When | Avoid When | Dorian's Domain Relevance |
|---------|----------|------------|--------------------------|
| **Repository** | Abstracting data access; multiple data sources; testability via mock/swap | Direct ORM/query builder in service layer suffices for simple CRUD | Data platform — separating Hive/Spark/MySQL access behind unified interface |
| **CQRS** | Read/write models diverge significantly; read-heavy with complex aggregated queries; separate scaling needs | Simple CRUD app — adds unnecessary split | Metadata management — read-heavy catalog queries vs. write-time governance rules |
| **Event Sourcing** | Full audit trail required; temporal queries ("what was the state at time T"); complex domain with undo | Simple state mutations; team lacks event-driven experience | Data lineage — tracking every schema change and its propagation |
| **Saga (Orchestration)** | Distributed transactions across services; compensation/rollback logic needed | Single-service transaction — use DB transaction | ETL pipeline — coordinating multi-step Flink jobs with failure recovery |
| **Saga (Choreography)** | Loosely coupled services reacting to events; no central coordinator needed | Need strict ordering or complex compensation | Event-driven metadata sync across systems |
| **Unit of Work** | Batch DB operations with atomic commit; change tracking | Simple single-entity saves | Batch metadata migration (7000+ tables) |

### Frontend-Specific Patterns

| Pattern | Use When | Avoid When |
|---------|----------|------------|
| **Container/Presenter** | Separating data-fetching from rendering; reusable UI components | Small component with trivial data needs |
| **Compound Component** | Related components sharing implicit state (Tabs, Accordion, Select, Sidebar) | Independent components with no shared state |
| **Render Props / Custom Hooks** | Sharing stateful logic across multiple components | Logic is used in only one place — inline it |
| **Finite State Machine (XState)** | Complex UI states with defined transitions (multi-step form, async workflows, media player) | Binary toggle or simple loading/error/success state |
| **Module Federation** | Micro-frontend with independent deployment and shared dependencies | Monolithic app or small team — overhead not justified |
| **Optimistic Update** | Low-latency UX for frequent writes (likes, toggles, inline edits) | Critical data where server confirmation is required before showing result |

---

## Anti-Pattern Checklist

When reviewing code or architecture, watch for:

| Anti-Pattern | Symptom | Remedy |
|-------------|---------|--------|
| **God Object/Function** | One module does everything, 500+ lines | Split by SRP, extract domain services |
| **Premature Abstraction** | Abstraction created before second use case | Inline first, extract when pattern emerges (Rule of Three) |
| **Pattern Mania** | GoF patterns applied to 20-line modules | If-else is not a crime. Simple code > clever code |
| **Leaky Abstraction** | Implementation details leaking through interface | Tighten the contract, hide internals |
| **Shotgun Surgery** | One logical change touches 10+ files | Consolidate related logic into cohesive module |
| **Feature Envy** | Function uses more data from another module than its own | Move the function to where the data lives |
| **N+1 Query** | Loop DB/API calls inside iteration | Batch query + in-memory join |
| **Distributed Monolith** | Microservices that must deploy together | If services can't deploy independently, merge them back |
| **Cargo Cult Architecture** | Copying patterns from big tech without matching scale | Design for your actual scale, not Netflix's |

---

## How to Apply

### During Brainstorming / Planning
1. Identify the core problem (extensibility? testability? performance? team boundaries?)
2. Check this guide for candidate patterns
3. Evaluate each against the Decision Flow (Section 2)
4. Present trade-offs to Dorian with a clear recommendation

### During Code Review
1. Check if applied patterns are justified (not over-engineered)
2. Scan for anti-patterns in the checklist above
3. Verify invariants from CLAUDE.md are not violated (layered architecture, SOLID, no-any)

### During Refactoring
1. Identify the anti-pattern causing pain
2. Choose the minimum pattern that resolves it
3. Refactor incrementally — don't rewrite entire module at once

---

## Key Reminders

- **CLAUDE.md invariants always apply**: Layered architecture, SOLID, Schema-First, no-any, etc.
- **This guide is contextual**: Patterns here are recommendations, not mandates. The right choice depends on the specific problem, scale, and team
- **When in doubt, choose simplicity**: Three similar lines of code is better than a premature abstraction
- **Dorian's domain is data platforms**: Patterns related to metadata management, ETL, data lineage, and OLAP have extra relevance
