---
description: Comprehensive reference for convex-helpers utilities including custom functions, relationships, pagination, rate limiting, and more
argument-hint: [helper-name]
allowed-tools: [Read, Glob, Grep, Bash, WebSearch]
---

# convex-helpers Guide

Reference for convex-helpers utility: $ARGUMENTS

Install: `npm install convex-helpers`

## Custom Functions

Create reusable function wrappers with built-in auth, validation, logging:

```typescript
import { customQuery, customMutation, customAction } from "convex-helpers/server/customFunctions";
import { query, mutation } from "./_generated/server";

// Auth wrapper
const authedQuery = customQuery(query, {
  args: {},
  input: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");
    const user = await ctx.db.query("users")
      .withIndex("by_token", q => q.eq("tokenIdentifier", identity.tokenIdentifier))
      .unique();
    if (!user) throw new Error("User not found");
    return { ctx: { ...ctx, user }, args: {} };
  },
});

// Usage - auth is automatic
export const myQuery = authedQuery({
  args: {},
  handler: async (ctx) => {
    // ctx.user is available and guaranteed
    return ctx.user.name;
  },
});
```

## Relationships

Load related documents without manual joins:

```typescript
import { getOneFrom, getManyFrom, getManyVia } from "convex-helpers/server/relationships";

// One-to-one or many-to-one
const author = await getOneFrom(ctx.db, "users", "by_id", post.authorId);

// One-to-many
const comments = await getManyFrom(ctx.db, "comments", "by_post", post._id);

// Many-to-many via junction table
const members = await getManyVia(ctx.db, "projectMembers", "by_project", project._id, "userId", "users");
```

## Advanced Pagination

For complex filtering/sorting beyond built-in `.paginate()`:

```typescript
import { getPage } from "convex-helpers/server/pagination";

export const filteredList = query({
  args: { paginationOpts: paginationOptsValidator, status: v.string() },
  handler: async (ctx, args) => {
    const allItems = await ctx.db.query("items")
      .withIndex("by_user", q => q.eq("userId", user._id))
      .collect();
    const filtered = allItems.filter(i => i.status === args.status);
    return getPage(filtered, args.paginationOpts);
  },
});
```

## Rate Limiting

```typescript
import { defineRateLimiter } from "convex-helpers/server/rateLimit";

const rateLimiter = defineRateLimiter(components.rateLimiter, {
  sendMessage: { kind: "token bucket", rate: 10, period: 60000, capacity: 10 },
});

export const sendMessage = mutation({
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);
    await rateLimiter.limit(ctx, "sendMessage", { key: user._id });
    // ... send message
  },
});
```

## Triggers

React to document changes:

```typescript
import { Triggers } from "convex-helpers/server/triggers";

const triggers = new Triggers();
triggers.register("tasks", async (ctx, change) => {
  if (change.newDoc && !change.oldDoc) {
    // Task was created
    await ctx.db.insert("activityLog", { action: "task_created", taskId: change.id });
  }
});
```

## Migrations

```typescript
import { makeMigration } from "convex-helpers/server/migrations";

const migration = makeMigration(internalMutation, {
  table: "users",
  migrateOne: async (ctx, doc) => {
    if (!doc.role) {
      await ctx.db.patch(doc._id, { role: "user" });
    }
  },
});
```

## Learn More

- [convex-helpers GitHub](https://github.com/get-convex/convex-helpers)
- [API documentation](https://github.com/get-convex/convex-helpers/tree/main/packages/convex-helpers)
