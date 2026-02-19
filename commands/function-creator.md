---
description: Create Convex queries, mutations, and actions with proper validation, auth, and error handling
argument-hint: <function-description>
allowed-tools: [Read, Write, Edit, Glob, Grep]
---

# Convex Function Creator

Create Convex functions for: $ARGUMENTS

## Function Types

### Query (read data, reactive)
```typescript
export const list = query({
  args: { userId: v.id("users") },
  returns: v.array(v.object({ /* ... */ })),
  handler: async (ctx, args) => {
    return await ctx.db
      .query("tasks")
      .withIndex("by_user", q => q.eq("userId", args.userId))
      .collect();
  },
});
```

### Mutation (write data, transactional)
```typescript
export const create = mutation({
  args: { title: v.string() },
  returns: v.id("tasks"),
  handler: async (ctx, args) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");
    const user = await getCurrentUser(ctx);
    return await ctx.db.insert("tasks", {
      title: args.title,
      userId: user._id,
      createdAt: Date.now(),
    });
  },
});
```

### Action (external APIs, "use node")
```typescript
"use node";
export const fetchExternal = action({
  args: { query: v.string() },
  handler: async (ctx, args) => {
    const response = await fetch(`https://api.example.com?q=${args.query}`);
    const data = await response.json();
    await ctx.runMutation(internal.data.store, { data });
    return data;
  },
});
```

## Required Patterns

1. **Always validate args and returns**
2. **Always check auth** in protected functions
3. **Always verify ownership** before mutations
4. **Use `.withIndex()`** not `.filter()` for queries
5. **Await all promises** - no floating promises
6. **Use `internal.*`** for scheduled functions
7. **Separate "use node" files** - only actions in those files
