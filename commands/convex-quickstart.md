---
description: Initialize a new Convex backend from scratch with schema, auth, and basic CRUD operations
argument-hint: [app-description]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# Convex Quickstart

Set up a production-ready Convex backend. Use when starting a new project or adding Convex to an existing app.

## Steps

1. **Install and Initialize**

```bash
npm install convex
npx convex dev
```

2. **Create Schema** (`convex/schema.ts`):

```typescript
import { defineSchema, defineTable } from "convex/server";
import { v } from "convex/values";

export default defineSchema({
  users: defineTable({
    name: v.string(),
    email: v.string(),
    tokenIdentifier: v.string(),
  }).index("by_token", ["tokenIdentifier"]),

  // Add your tables here based on the app description: $ARGUMENTS
});
```

3. **Create Auth Helpers** (`convex/users.ts`):

```typescript
import { query, mutation } from "./_generated/server";
import { v } from "convex/values";

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
    });
  },
});

export const current = query({
  args: {},
  handler: async (ctx) => {
    const identity = await ctx.auth.getUserIdentity();
    if (!identity) return null;

    return await ctx.db
      .query("users")
      .withIndex("by_token", q => q.eq("tokenIdentifier", identity.tokenIdentifier))
      .unique();
  },
});
```

4. **Create CRUD Operations** for each table with:
   - `args` and `returns` validators
   - Authentication checks
   - Indexed queries (no `.filter()`)
   - Proper error handling

5. **Set Up Frontend Provider**:

```typescript
import { ConvexProvider, ConvexReactClient } from "convex/react";

const convex = new ConvexReactClient(process.env.NEXT_PUBLIC_CONVEX_URL!);

function App({ children }) {
  return <ConvexProvider client={convex}>{children}</ConvexProvider>;
}
```

## Checklist

- [ ] `convex/schema.ts` with all tables and indexes
- [ ] Auth helper functions (store user, get current user)
- [ ] CRUD operations with validation and auth
- [ ] Frontend provider configured
- [ ] `npx convex dev` running successfully
