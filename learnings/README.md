# Continuous Learning System

## Overview

The Continuous Learning System allows Claude Code to capture reusable patterns
discovered during sessions and promote them into permanent skills when proven.

## Two-Stage Pipeline

```
Session Discovery --> /learn --> instincts.json --> /evolve --> skills/{tag}-learned/SKILL.md
                      (0.3)      confidence grows    (0.7+)     permanent skill
```

## Stage 1: Instincts (`/learn`)

An **instinct** is a pattern observation with a confidence score.

| Field | Description |
|---|---|
| id | Unique identifier (inst_001, inst_002, ...) |
| pattern | Human-readable description of the pattern |
| confidence | Score from 0.3 to 0.9 |
| evidence | List of session references that confirmed the pattern |
| created | Date first observed |
| last_confirmed | Date of most recent confirmation |
| tags | Category labels for grouping |
| source | "user" (explicit /learn) or "auto" (detected) |
| evolved_to | Name of skill this was promoted to (null if not yet) |

### Confidence Progression

```
0.3  New pattern (first observation)
0.5  Confirmed once (second observation, +0.2)
0.7  Strong pattern (third observation, evolution candidate)
0.9  Maximum confidence (fourth observation, cap)
```

Each time the same pattern is observed again, confidence increases by 0.2.
Duplicate detection uses fuzzy word matching (60% overlap threshold).

## Stage 2: Evolution (`/evolve`)

When 3 or more instincts in the same tag group reach confidence >= 0.7,
they can be **evolved** into a permanent skill file.

### Evolution Rules

- Minimum 3 high-confidence instincts per tag group required
- Evolved instincts are marked with `evolved_to` field
- Generated skills are saved to `~/.claude/skills/{tag}-learned/SKILL.md`
- Existing evolved skills can be extended with new patterns

## File Structure

```
~/.claude/
  learnings/
    instincts.json    # All instincts with confidence scores
    README.md         # This file
  skills/
    learn/SKILL.md    # The /learn skill definition
    evolve/SKILL.md   # The /evolve skill definition
    {tag}-learned/    # Auto-generated evolved skills
      SKILL.md
```

## Usage

```
/learn Use parallel Glob calls for multi-file search    # Capture a pattern
/learn                                                   # Auto-detect from session
/evolve                                                  # Promote proven patterns to skills
```
