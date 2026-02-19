---
description: Design and generate Convex database schemas with proper validation, indexes, and relationships
argument-hint: <table-description>
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Convex Schema Builder

Build well-structured Convex schemas for: $ARGUMENTS

## Design Principles

1. **Document-Relational**: Flat documents with ID references, not deep nesting
2. **Index Foreign Keys**: Always index fields used in lookups
3. **Limit Arrays**: Only for small, bounded collections (<8192 items)
4. **Type Safety**: Strict validators with `v.*` types

## Schema Template

```typescript
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  tableName: defineTable({
    field: v.string(),
    optional: v.optional(v.number()),
    userId: v.id("users"),
    status: v.union(v.literal("active"), v.literal("archived")),
    createdAt: v.number(),
  })
    .index("by_user", ["userId"])
    .index("by_user_and_status", ["userId", "status"]),
});
```

## Relationship Patterns

**One-to-Many**: Foreign key + index on child table
**Many-to-Many**: Junction table with indexes on both foreign keys
**Hierarchical**: Optional self-referencing `parentId`

## Validator Reference

- `v.string()`, `v.number()`, `v.boolean()`, `v.null()`
- `v.id("tableName")` for relations
- `v.optional(v.string())` for optional fields
- `v.union(v.literal("a"), v.literal("b"))` for enums
- `v.object({ key: v.string() })` for nested objects
- `v.array(v.string())` for arrays (keep small)

## Index Strategy

1. Single-field: `by_email: ["email"]`
2. Compound: `by_user_and_status: ["userId", "status"]`
3. Remove redundant: `by_a_and_b` covers `by_a`

## Checklist

- [ ] All foreign keys have indexes
- [ ] Compound indexes for common query patterns
- [ ] Arrays are small and bounded
- [ ] All fields have proper validators
- [ ] Enums use `v.union(v.literal(...))` pattern
- [ ] Timestamps use `v.number()` (milliseconds)
