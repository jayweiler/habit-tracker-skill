# Habit Tracker — Design Methodology

## Origin

This skill emerged from a real productivity system built over 55+ sessions between a human and an AI assistant. The habit tracking component started as hardcoded instructions scattered across multiple system files: habit definitions in one file, check-in protocols in another, logging logic implied in a third. It worked, but it consumed mandatory context every session whether habits came up or not.

The extraction into a standalone skill was part of a broader "context engineering" effort — treating the AI's context window as a scarce resource that needs budgeting, like RAM or attention.

## Design Principles

### 1. Never Assume False

The single most important rule. Early in the system's development, the AI logged three habits as `false` without asking about them. All three had actually been completed. This destroyed trust in the tracking data.

The fix: every habit must be asked about individually. If you didn't ask, you don't log. This is non-negotiable and applies even when the user gives a partial batch response.

### 2. Log Immediately, Not Later

When habit data is collected during conversation, it must be written to the log file immediately — not batched to session end. Sessions can be interrupted, compacted, or abandoned. Deferred writes are lost writes.

### 3. Three States, Not Two

Binary done/not-done misses a real scenario: someone else did the habit for you. "Covered" (someone else handled it) is a third state that matters for streak integrity. A covered day shouldn't break a streak (you didn't fail), but it also shouldn't build one (you didn't do the work). This distinction preserves the motivational value of streaks.

### 4. Config-Driven, Not Hardcoded

Habits are deeply personal. What matters to one person is irrelevant to another. The skill must work with any set of user-defined habits, not a predetermined list. The YAML config is the single source of truth for what habits exist, when they apply, and how they're grouped.

### 5. Context Efficiency Through On-Demand Loading

The original system loaded habit definitions and check-in protocols at the start of every session, consuming ~2KB+ of mandatory context. The skill version loads only when triggered — when the user mentions habits, during morning/evening check-ins, or when another system (like a planning protocol) invokes it. This is the key architectural win: same functionality, lower context tax.

### 6. Retention Windows for Time-Series Data

A habit log grows linearly. Without maintenance, it becomes a context burden. The 30-day retention window keeps the active file lean while preserving history in an archive. The archive exists for long-term analysis (monthly reviews, trend reports) but doesn't load during routine check-ins.

### 7. Schedule Awareness

Not all habits apply every day. A habit scheduled for weekdays only shouldn't penalize the user on Saturday. A Saturday-only habit shouldn't show as "missed" on Tuesday. Schedule-aware streak calculation prevents false negatives from confusing the tracking data.

### 8. Graceful Degradation

The skill should work at multiple levels of engagement:
- Full daily check-in with streak reporting (ideal)
- Quick batch response with follow-up on unmentioned habits (common)
- "Just log today" with no streak report (minimal)
- Multi-day gap recovery without guilt (reality)

The user's energy and available time determine the level, not the skill's preferences.

## What This Skill Intentionally Does Not Do

- **Render visualizations.** The skill produces data (JSON) and text-based grids. If you want fancy charts, dashboards, or printable cards, build a renderer that reads the log file. Separation of concerns.

- **Set goals or targets.** The skill tracks what happened, not what should happen. Goal-setting is a coaching concern, not a tracking concern. The user's broader productivity system can layer goals on top.

- **Judge or motivate.** The skill reports facts: "PT: 0 days, last done 3 days ago." It does not say "You should really do your PT." Motivation belongs to the user or their coaching system. The skill's job is accurate data.

- **Own the user's schedule.** The skill knows when habits are scheduled, but it doesn't manage the user's calendar, planning, or time allocation. It answers "did you do it?" not "when will you do it?"
