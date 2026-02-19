---
description: Set up Convex authentication with user management, identity mapping, and access control
argument-hint: [auth-provider]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# Convex Auth Setup

Set up authentication for your Convex app. Provider: $ARGUMENTS

## Steps

### 1. Users Table Schema

```typescript
// convex/schema.ts
users: defineTable({
  name: v.string(),
  email: v.string(),
  tokenIdentifier: v.string(),
  role: v.optional(v.union(v.literal("user"), v.literal("admin"))),
}).index("by_token", ["tokenIdentifier"])
  .index("by_email", ["email"]),
```

### 2. Auth Helper Functions

```typescript
// convex/users.ts
export const store = mutation({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) throw new Error("Not authenticated");

    const user = await ctx.db
      .query("users")
      .withIndex("by_token", q => q.eq("tokenIdentifier", identity.tokenIdentifier))
      .unique();

    if (user !== null) return user._id;

    return await ctx.db.insert("users", {
      name: identity.name ?? "Anonymous",
      email: identity.email ?? "",
      tokenIdentifier: identity.tokenIdentifier,
      role: "user",
    });
  },
});

// Reusable helper
export async function getCurrentUser(ctx: QueryCtx) {
  const identity = await ctx.auth.getUserIdentity();
  if (!identity) throw new Error("Not authenticated");

  const user = await ctx.db
    .query("users")
    .withIndex("by_token", q => q.eq("tokenIdentifier", identity.tokenIdentifier))
    .unique();

  if (!user) throw new Error("User not found");
  return user;
}
```

### 3. Protected Functions Pattern

```typescript
export const myProtectedMutation = mutation({
  args: { /* ... */ },
  handler: async (ctx, args) => {
    const user = await getCurrentUser(ctx);
    // user is guaranteed authenticated
  },
});
```

### 4. Role-Based Access

```typescript
export async function requireAdmin(ctx: QueryCtx) {
  const user = await getCurrentUser(ctx);
  if (user.role !== "admin") throw new Error("Admin access required");
  return user;
}
```

## Provider Setup

### WorkOS
```typescript
// auth.config.ts
export default {
  providers: [{ domain: "https://your-workos-domain.com" }],
};
```

### Auth0
```typescript
export default {
  providers: [{ domain: "https://your-auth0-domain.auth0.com" }],
};
```

## Checklist

- [ ] Users table with `tokenIdentifier` index
- [ ] `store` mutation for first sign-in
- [ ] `getCurrentUser` helper function
- [ ] Auth provider configured in `auth.config.ts`
- [ ] Frontend auth provider wrapper
- [ ] All protected functions use `getCurrentUser`
