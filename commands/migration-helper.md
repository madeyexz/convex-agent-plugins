---
description: Plan and execute Convex schema migrations safely without downtime
argument-hint: <migration-description>
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# Convex Migration Helper

Plan a safe migration for: $ARGUMENTS

## Migration Strategy

### Adding a Required Field

1. **Add as optional first:**
```typescript
users: defineTable({
  name: v.string(),
  role: v.optional(v.union(v.literal("user"), v.literal("admin"))),
})
```

2. **Write migration function:**
```typescript
export const backfillRoles = internalMutation({
  args: { batchSize: v.optional(v.number()) },
  handler: async (ctx, args) => {
    const batchSize = args.batchSize ?? 100;
    const users = await ctx.db.query("users").take(batchSize);

    for (const user of users) {
      if (!user.role) {
        await ctx.db.patch(user._id, { role: "user" });
      }
    }

    return { processed: users.length, hasMore: users.length === batchSize };
  },
});
```

3. **Run migration:** `npx convex run migrations:backfillRoles`
4. **Verify all records updated**
5. **Make field required in schema**

### Dual-Write Pattern (Zero Downtime)

Write to both old and new structure during transition:

```typescript
export const createPost = mutation({
  args: { title: v.string(), tags: v.array(v.string()) },
  handler: async (ctx, args) => {
    // Write to old structure
    const postId = await ctx.db.insert("posts", { title: args.title, tags: args.tags });

    // ALSO write to new structure
    for (const tagName of args.tags) {
      let tag = await ctx.db.query("tags")
        .withIndex("by_name", q => q.eq("name", tagName)).unique();
      if (!tag) {
        const tagId = await ctx.db.insert("tags", { name: tagName });
        tag = { _id: tagId };
      }
      await ctx.db.insert("postTags", { postId, tagId: tag._id });
    }
    return postId;
  },
});
```

### Verify Migration

```typescript
export const verifyMigration = query({
  handler: async (ctx) => {
    const total = (await ctx.db.query("users").collect()).length;
    const migrated = (await ctx.db.query("users")
      .filter(q => q.neq(q.field("role"), undefined)).collect()).length;
    return { total, migrated, remaining: total - migrated };
  },
});
```

## Checklist

- [ ] Add new structure as optional/additive
- [ ] Write batch migration function
- [ ] Test on sample data
- [ ] Run migration in batches
- [ ] Verify completion
- [ ] Update application code
- [ ] Make field required
- [ ] Clean up migration code
