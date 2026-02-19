# Convex Plugin for Claude Code

Official Convex plugin for Claude Code, providing comprehensive development tools for building reactive backends with TypeScript.

> Forked from [get-convex/convex-agent-plugins](https://github.com/get-convex/convex-agent-plugins) and adapted for the Claude Code plugin marketplace.

## Overview

This plugin makes Convex development easier by providing:

- **Best Practice Skills** -- Auto-invoked guidance for query optimization, security, schema design, and more
- **7 Slash Commands** -- On-demand expertise for quickstart, schema building, function creation, auth, migrations, and helpers
- **2 Specialized Agents** -- Convex advisor and code reviewer
- **MCP Integration** -- Direct access to your Convex deployment via `npx convex mcp start`
- **Pre-Commit Hooks** -- Automated checks for common Convex anti-patterns

## Installation

### From Marketplace

```
/plugin marketplace add madeyexz/convex-agent-plugins
/plugin install convex@convex-plugins
```

### Manual

```bash
git clone https://github.com/madeyexz/convex-agent-plugins.git
claude --plugin-dir ./convex-agent-plugins
```

## What is Convex?

[Convex](https://convex.dev) is the reactive backend-as-a-service where you build your entire backend in TypeScript:

- **Reactive Database** -- Real-time queries that automatically update your UI
- **Serverless Functions** -- Queries, mutations, and actions in TypeScript
- **Built-in Auth** -- WorkOS, Auth0, or custom JWT integration
- **Type Safety** -- End-to-end TypeScript with automatic type generation
- **Vector Search** -- Built-in vector database for AI applications

## Components

### Skills (Auto-Invoked)

The `convex-best-practices` skill automatically activates when working in `convex/` directories, providing guidance on:

- Query optimization (use `.withIndex()` not `.filter()`)
- Async handling (always await promises)
- Argument/return validation
- Authentication & authorization patterns
- Schema design (flat, relational, indexed)
- Function organization (thin wrappers)
- Scheduler usage (only `internal.*`)
- No `Date.now()` in queries
- `"use node"` directive usage
- Pagination for large datasets
- ESLint setup
- TypeScript strict mode

### Slash Commands

| Command | Description |
|---------|-------------|
| `/convex:convex-quickstart` | Initialize a new Convex backend from scratch |
| `/convex:schema-builder` | Design schemas with proper indexes and relationships |
| `/convex:function-creator` | Create queries, mutations, actions with validation and auth |
| `/convex:auth-setup` | Set up authentication and access control |
| `/convex:migration-helper` | Plan safe schema migrations without downtime |
| `/convex:components-guide` | Discover Convex components and patterns |
| `/convex:convex-helpers-guide` | Reference for convex-helpers utilities |

### Agents

- **convex-advisor** -- Architecture guidance, migration paths, feature recommendations
- **convex-reviewer** -- Security, performance, and best practice code reviews

### MCP Server

Provides direct access to your Convex deployment. Requires environment variables:

```bash
export CONVEX_DEPLOYMENT="your-deployment-name"
export CONVEX_DEPLOY_KEY="your-deploy-key"
```

### Pre-Commit Hooks

Automatically blocks commits containing:
- `Date.now()` near Convex query functions (breaks reactivity)
- `.filter()` on `db.query()` calls (should use `.withIndex()`)

## Plugin Structure

```
convex-agent-plugins/
├── .claude-plugin/
│   ├── plugin.json          # Plugin manifest
│   └── marketplace.json     # Marketplace config
├── skills/
│   └── convex-best-practices/
│       └── SKILL.md         # Auto-invoked best practices
├── commands/
│   ├── convex-quickstart.md
│   ├── schema-builder.md
│   ├── function-creator.md
│   ├── auth-setup.md
│   ├── migration-helper.md
│   ├── components-guide.md
│   └── convex-helpers-guide.md
├── agents/
│   ├── convex-advisor.md
│   └── convex-reviewer.md
├── hooks/
│   └── hooks.json
├── scripts/
│   └── pre-commit-checks.sh
├── .mcp.json
└── README.md
```

## Best Practices Enforced

**Security:** Validate arguments, check auth, verify ownership, use internal functions for scheduling

**Performance:** Use indexed queries, paginate large datasets, avoid `Date.now()` in queries

**Schema:** Flat relational structure, index foreign keys, bounded arrays, proper validators

**Code Quality:** Await all promises, thin wrappers, no `any` types, clear error handling

## Learn More

- [Convex Documentation](https://docs.convex.dev)
- [Convex Best Practices](https://docs.convex.dev/understanding/best-practices/)
- [convex-helpers](https://github.com/get-convex/convex-helpers)
- [Convex Discord](https://convex.dev/community)

## License

MIT License - See LICENSE file for details.
