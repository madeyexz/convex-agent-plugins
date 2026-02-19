---
name: convex-best-practices
description: Convex development best practices for queries, mutations, actions, schema design, security, and performance. Auto-activates when working in convex/ directories or with Convex TypeScript files. Triggers on convex queries, mutations, actions, schema, indexes, validators, authentication, real-time, reactive, "use node", pagination, scheduling.
---

# Convex Best Practices

Comprehensive guidance for writing correct, secure, and performant Convex backend code.

## Query Optimization

Use indexes instead of `.filter()` for efficient database queries.

**Bad:**
```typescript
const user = await ctx.db
  .query("users")
  .filter(q => q.eq(q.field("email"), email))
  .first();
```

**Good:**
```typescript
const user = await ctx.db
  .query("users")
  .withIndex("by_email", q => q.eq("email", email))
  .first();
```

## Async Handling

Always await promises to prevent unexpected behavior. Floating promises are a common source of bugs.

**Bad:**
```typescript
ctx.db.insert("tasks", args); // Missing await!
```

**Good:**
```typescript
await ctx.db.insert("tasks", args);
```

## Argument & Return Validation

All public functions must validate args and returns:

```typescript
export const createTask = mutation({
  args: { title: v.string(), userId: v.id("users") },
  returns: v.id("tasks"),
  handler: async (ctx, args) => {
    return await ctx.db.insert("tasks", args);
  },
});
```

## Authentication & Authorization

All protected functions must check authentication:

```typescript
export const deleteTask = mutation({
  args: { taskId: v.id("tasks") },
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");

    const task = await ctx.db.get(args.taskId);
    if (!task) throw new Error("Task not found");

    const user = await getCurrentUser(ctx);
    if (task.userId !== user._id) throw new Error("Unauthorized");

    await ctx.db.delete(args.taskId);
  },
});
```

## Schema Design

Design flat, relational schemas with proper indexes:

```typescript
export default defineSchema({
  users: defineTable({
    name: v.string(),
    email: v.string(),
  }).index("by_email", ["email"]),

  posts: defineTable({
    userId: v.id("users"),
    title: v.string(),
    content: v.string(),
  }).index("by_user", ["userId"]),
});
```

**Rules:**
- Use flat documents with ID references, not deep nesting
- Always index foreign key fields
- Use `v.union(v.literal(...))` for enums
- Arrays only for small, bounded collections
- Many-to-many via junction tables

## Function Organization

Keep query/mutation/action wrappers thin. Put business logic in plain TypeScript functions:

```typescript
// helpers.ts
export function calculateDiscount(price: number, tier: string): number {
  // Business logic here
}

// convex/orders.ts
export const applyDiscount = mutation({
  args: { orderId: v.id("orders") },
  handler: async (ctx, args) => {
    const order = await ctx.db.get(args.orderId);
    const discount = calculateDiscount(order.price, order.tier);
    await ctx.db.patch(args.orderId, { discount });
  },
});
```

## Scheduler Usage

Only schedule internal functions, never `api` functions:

**Bad:**
```typescript
await ctx.scheduler.runAfter(0, api.tasks.process, args);
```

**Good:**
```typescript
await ctx.scheduler.runAfter(0, internal.tasks.process, args);
```

## No Date.now() in Queries

Avoid `Date.now()` in queries as it breaks reactivity. Use arguments or status fields instead:

**Bad:**
```typescript
export const getActive = query({
  handler: async (ctx) => {
    const now = Date.now(); // Breaks reactivity!
    return await ctx.db.query("tasks")
      .filter(q => q.lt(q.field("due"), now))
      .collect();
  },
});
```

**Good:**
```typescript
export const getActive = query({
  args: { now: v.number() },
  handler: async (ctx, args) => {
    return await ctx.db.query("tasks")
      .withIndex("by_due", q => q.lt("due", args.now))
      .collect();
  },
});
```

## "use node" Directive

Files with `"use node"` can ONLY contain `action` and `internalAction`. Never put queries or mutations in `"use node"` files:

```typescript
// convex/externalActions.ts
"use node";

import { action } from "./_generated/server";

export const fetchWeather = action({
  args: { city: v.string() },
  handler: async (ctx, args) => {
    const response = await fetch(`https://api.weather.com/${args.city}`);
    const data = await response.json();
    await ctx.runMutation(internal.weather.store, { city: args.city, data });
    return data;
  },
});
```

## Pagination

Use cursor-based pagination for large datasets instead of `.collect()`:

```typescript
import { paginationOptsValidator } from "convex/server";

export const listTasks = query({
  args: { paginationOpts: paginationOptsValidator },
  handler: async (ctx, args) => {
    return await ctx.db
      .query("tasks")
      .order("desc")
      .paginate(args.paginationOpts);
  },
});
```

Frontend:
```typescript
const { results, status, loadMore } = usePaginatedQuery(
  api.tasks.listTasks, {}, { initialNumItems: 20 }
);
```

## Custom Functions for Auth (RLS Alternative)

Use custom function wrappers for data protection:

```typescript
import { customQuery } from "convex-helpers/server/customFunctions";

const authedQuery = customQuery(query, {
  args: {},
  input: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");
    return { ctx: { ...ctx, identity }, args: {} };
  },
});

export const myProtectedQuery = authedQuery({
  args: { taskId: v.id("tasks") },
  handler: async (ctx, args) => {
    // ctx.identity is guaranteed to exist
    return await ctx.db.get(args.taskId);
  },
});
```

## ESLint

ESLint with `@convex-dev/eslint-plugin` is mandatory for production apps:

```bash
npm install --save-dev @convex-dev/eslint-plugin
```

```javascript
// eslint.config.mjs
import convexPlugin from "@convex-dev/eslint-plugin";
export default [...convexPlugin.configs.recommended];
```

## Error Handling

Throw errors for authorization failures (client gets generic error). Return null for expected "not found" cases:

```typescript
// Throw for auth/authorization failures
if (!identity) throw new Error("Not authenticated");
if (task.userId !== user._id) throw new Error("Unauthorized");

// Return null for expected empty results
const task = await ctx.db.get(args.taskId);
if (!task) return null;
```

## TypeScript Strict Mode

Enable strict mode. Avoid `any` type:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true
  }
}
```

## Components for Encapsulation

Use sibling Convex components for modularity when building larger apps. Components encapsulate their own schema, functions, and indexes.

## Index Strategy Summary

1. **Single-field indexes**: For simple lookups (`by_email: ["email"]`)
2. **Compound indexes**: For filtered queries (`by_user_and_status: ["userId", "status"]`)
3. **Remove redundant**: `by_a_and_b` usually covers `by_a`
4. **Index all foreign keys**: Every `v.id("table")` field needs an index
