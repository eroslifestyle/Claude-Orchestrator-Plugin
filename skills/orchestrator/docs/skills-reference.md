# Skills Reference

> Orchestrator V12.0 - Skills Reference Guide

Source: https://code.claude.com/docs/en/skills

Skills extend what Claude can do. Create a `SKILL.md` file with instructions, and Claude adds it to its toolkit. Claude uses skills when relevant, or you can invoke one directly with `/skill-name`.

## Skill Locations

| Location | Path | Applies to |
|----------|------|------------|
| Enterprise | See managed settings | All users in your organization |
| Personal | `~/.claude/skills/<skill-name>/SKILL.md` | All your projects |
| Project | `.claude/skills/<skill-name>/SKILL.md` | This project only |
| Plugin | `<plugin>/skills/<skill-name>/SKILL.md` | Where plugin is enabled |

Priority: enterprise > personal > project. Plugin skills use `plugin-name:skill-name` namespace.

## Skill Structure

```
my-skill/
├── SKILL.md           # Main instructions (required)
├── template.md        # Template for Claude to fill in
├── examples.md        # Example output showing expected format
├── reference.md       # Detailed reference docs
└── scripts/
    └── helper.py      # Script Claude can execute
```

## Frontmatter Reference

```yaml
---
name: my-skill                    # Display name (lowercase, numbers, hyphens)
description: What this skill does # Claude uses this to decide when to apply
argument-hint: [issue-number]     # Hint shown during autocomplete
disable-model-invocation: false   # Set true to prevent Claude auto-loading
user-invocable: true              # Set false to hide from / menu
allowed-tools: Read, Grep, Glob   # Tools Claude can use without asking
model: haiku                      # Model to use when skill is active
context: fork                     # Run in forked subagent context
agent: Explore                    # Which subagent type to use with context: fork
hooks: {}                         # Hooks scoped to skill lifecycle
---
```

### Invocation Control

| Frontmatter | You can invoke | Claude can invoke | When loaded into context |
|-------------|----------------|-------------------|--------------------------|
| (default) | Yes | Yes | Description always in context, full skill loads when invoked |
| `disable-model-invocation: true` | Yes | No | Description not in context, full skill loads when you invoke |
| `user-invocable: false` | No | Yes | Description always in context, full skill loads when invoked |

## String Substitutions

| Variable | Description |
|----------|-------------|
| `$ARGUMENTS` | All arguments passed when invoking the skill |
| `$ARGUMENTS[N]` | Access specific argument by 0-based index (e.g., `$ARGUMENTS[0]`) |
| `$N` | Shorthand for `$ARGUMENTS[N]` (e.g., `$0`, `$1`, `$2`) |
| `${CLAUDE_SESSION_ID}` | Current session ID for logging/correlation |

**Example:**
```yaml
---
name: fix-issue
description: Fix a GitHub issue
disable-model-invocation: true
---

Fix GitHub issue $ARGUMENTS following our coding standards.
```

Running `/fix-issue 123` → "Fix GitHub issue 123 following our coding standards."

## Dynamic Context Injection

The `!`command`` syntax runs shell commands BEFORE the skill content is sent to Claude. The output replaces the placeholder.

**Example:**
```yaml
---
name: pr-summary
description: Summarize changes in a pull request
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull request context
- PR diff: !`gh pr diff`
- PR comments: !`gh pr view --comments`
- Changed files: !`gh pr diff --name-only`

## Your task
Summarize this pull request...
```

This is PREPROCESSING - commands execute before Claude sees anything. Claude only sees the final result.

## Run Skills in Subagent

Add `context: fork` to run a skill in an isolated subagent context. The skill content becomes the prompt.

**Example:**
```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS thoroughly:
1. Find relevant files using Glob and Grep
2. Read and analyze the code
3. Summarize findings with specific file references
```

The `agent` field specifies which subagent configuration to use:
- Built-in: `Explore`, `Plan`, `general-purpose`
- Custom: Any agent from `.claude/agents/`
- Default: `general-purpose`

## Tool Restrictions

Use `allowed-tools` to limit which tools Claude can use:

```yaml
---
name: safe-reader
description: Read files without making changes
allowed-tools: Read, Grep, Glob
---
```

## Types of Skill Content

### Reference Content
Adds knowledge Claude applies to current work (conventions, patterns, style guides).

```yaml
---
name: api-conventions
description: API design patterns for this codebase
---

When writing API endpoints:
- Use RESTful naming conventions
- Return consistent error formats
- Include request validation
```

### Task Content
Step-by-step instructions for specific actions. Add `disable-model-invocation: true` for manual-only invocation.

```yaml
---
name: deploy
description: Deploy the application to production
context: fork
disable-model-invocation: true
---

Deploy the application:
1. Run the test suite
2. Build the application
3. Push to the deployment target
```

## Supporting Files

Keep `SKILL.md` under 500 lines. Move detailed reference material to separate files.

Reference from SKILL.md:
```markdown
## Additional resources
- For complete API details, see `reference.md`
- For usage examples, see `examples.md`
```

## Permission Control

### Disable all skills
```
# Add to deny rules in /permissions:
Skill
```

### Allow/deny specific skills
```
# Allow only specific skills
Skill(commit)
Skill(review-pr *)

# Deny specific skills
Skill(deploy *)
```

Permission syntax: `Skill(name)` for exact match, `Skill(name *)` for prefix match.

## Troubleshooting

### Skill not triggering
1. Check description includes keywords users would naturally say
2. Verify skill appears in "What skills are available?"
3. Rephrase request to match description more closely
4. Invoke directly with `/skill-name` if user-invocable

### Skill triggers too often
1. Make description more specific
2. Add `disable-model-invocation: true` for manual-only invocation

### Claude doesn't see all skills
Skill descriptions load into context (2% of context window, ~16K char fallback).
Run `/context` to check for excluded skills warning.
Override limit with `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable.
