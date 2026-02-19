---
description: Guide for discovering and using Convex components and convex-helpers utilities
argument-hint: [component-or-pattern]
allowed-tools: [Read, Glob, Grep, Bash, WebSearch]
---

# Convex Components Guide

Discover and use Convex components and helpers for: $ARGUMENTS

## convex-helpers Package

Install: `npm install convex-helpers`

### Available Utilities

**Server Helpers:**
- `customFunctions` - Create custom query/mutation/action wrappers with auth, logging, etc.
- `relationships` - Load related documents (`getOneFrom`, `getManyFrom`, `getManyVia`)
- `pagination` - Advanced pagination with `getPage` for custom sort/filter
- `rowLevelSecurity` - Row-level security rules
- `triggers` - React to document changes
- `rateLimit` - Rate limiting for functions
- `migrations` - Schema migration utilities
- `validators` - Extra validator helpers

**React Helpers:**
- `useStableQuery` - Prevents UI flicker on requery
- `sessions` - Session management without auth

### Common Patterns

**Loading Related Data:**
```typescript
import { getOneFrom, getManyFrom } from "convex-helpers/server/relationships";

const author = await getOneFrom(ctx.db, "users", "by_id", post.authorId);
const comments = await getManyFrom(ctx.db, "comments", "by_post", post._id);
```

**Custom Auth Wrapper:**
```typescript
import { customQuery, customMutation } from "convex-helpers/server/customFunctions";

const authedQuery = customQuery(query, {
  args: {},
  input: async (ctx) => {
    const user = await getCurrentUser(ctx);
    return { ctx: { ...ctx, user }, args: {} };
  },
});
```

**Rate Limiting:**
```typescript
import { rateLimit } from "convex-helpers/server/rateLimit";

const limiter = rateLimit(ctx, { name: "sendMessage", count: 10, period: 60000 });
if (!limiter.ok) throw new Error("Rate limited");
```

## Official Convex Components

Search npm for `@convex-dev/*` packages for official components like:
- `@convex-dev/auth` - Authentication
- `@convex-dev/eslint-plugin` - ESLint rules
- `@convex-dev/aggregate` - Aggregation queries

## Learn More

- [convex-helpers docs](https://github.com/get-convex/convex-helpers)
- [Convex Components](https://www.convex.dev/components)
- [Stack articles](https://stack.convex.dev)
