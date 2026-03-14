---
name: habit-tracker
description: "Daily habit tracking with streaks, check-in protocols, and flexible scheduling. Use this skill whenever the user wants to: check in on habits, log habit completions, review streaks, set up new habits, do a morning or evening routine check-in, or mentions 'habits', 'routine', 'streak', 'check-in', 'did I do', or 'log my'. Also triggers on session-end reviews when habits haven't been logged yet. Works with any set of user-defined habits — no predefined habits required."
---

# Habit Tracker

A structured daily habit tracking skill for AI assistants. Handles check-ins, logging, streak reporting, and flexible scheduling without requiring any specific habits — the user defines what matters to them.

## What This Skill Does

This skill manages a complete habit tracking workflow:

- **Check-in protocol** that asks about each habit individually (never assumes)
- **JSON-based logging** with three states: done, missed, and covered
- **Streak tracking** with visual contribution grids
- **Flexible scheduling** — daily, specific days, conditional, or routine-grouped habits
- **Session integration** — works as a gate in morning planning, evening review, or standalone check-in
- **Graceful initialization** — walks new users through habit setup on first use

The skill is config-driven. Habits are defined in `habit-config.yaml`, completions are logged in `habit-log.json`. The skill reads the config to know what to ask about and when.

---

## Session Start Protocol

When the skill triggers (user mentions habits, check-in, routines, or streaks):

### Step 1: Find the Config

Search for `habit-config.yaml` in the user's workspace:

1. **Scan the workspace** — Look in the workspace root and one level deep for `habit-config.yaml`. Exclude the skill's own `templates/` directory.
   - **Found** — Load it.
   - **Not found** — Ask: "Want to set up habit tracking? I'll walk you through defining your habits." Run the initialization flow (see [First-Time Setup](#first-time-setup)).

2. **Find the log file** — The config's `log_file` field points to the JSON log. If the file doesn't exist, create it as an empty JSON object `{}`.

### Step 2: Determine Check-In Timing

Check the current time and determine what to ask about:

- **Morning session** (before noon): Ask about yesterday's habits (if not already logged).
- **Evening session** (after noon): Ask about today's habits.
- **If already logged for the target date**: Report streaks and skip the check-in, or ask if the user wants to update any entries.

The config's `timezone` field controls what "today" means. Always verify the current time: `TZ='<timezone>' date`.

### Step 3: Run the Check-In

For each active habit on the target date:

1. **Check the schedule.** Only ask about habits that apply today (e.g., skip "Pack swim bag" on non-Saturdays, skip "Include kid in dinner prep" on non-Wed/Thu).
2. **Ask individually.** Never batch-assume. Never default to false. Say: "Did you [habit]?" for each one.
3. **Accept three responses:**
   - **Done** (true) — The user completed the habit.
   - **Missed** (false) — The user didn't do it. No guilt, no judgment. Just log it.
   - **Covered** ("covered") — Someone else handled it. Covered days don't break streaks but don't build them either.
4. **Log immediately.** Don't batch logging to session end. Write each response to the log file as it's given.

### Step 4: Report Streaks

After logging, show a brief streak summary:

```
Streaks:
  Water in the morning: 5 days ■■■■■
  Oatmeal: 2 days ■■
  PT exercises: 0 (last: 3 days ago)
  Evening routine: 3 days ■■■
```

Celebrate streaks of 7+ days. Gently note broken streaks without guilt — the point is awareness, not shame. If the user has a values framework or motivational system, reference it when appropriate (e.g., "measure yourself by how you rise" for a broken streak).

---

## The Check-In Protocol

### Rules (Non-Negotiable)

1. **Never assume false on unasked habits.** If you didn't explicitly ask about a habit, don't log it. The user may have done it.

2. **Ask about every active habit individually.** Don't say "Did you do everything?" or "Anything else you did today?" Each habit gets its own question.

3. **"Loaded" counts as done for threshold habits.** Some habits have a `threshold_note` in the config (e.g., dishwasher: "loading it counts even if you don't run it"). Respect the user's definition of done.

4. **Log immediately when data is collected.** Don't defer or batch. The moment the user tells you about a habit, write it to the log.

5. **Don't skip habits because the session is busy.** Habit tracking is a gate, not an optional add-on. If the session is a coding sprint, a planning session, or an evening check-in, habits still get logged. Keep it quick (2-3 minutes), but do it.

6. **Respect the user's energy.** The check-in should feel like a quick inventory, not an interrogation. Group by category, move fast, don't editorialize on individual misses.

### Handling Partial Check-Ins

If the user gives a batch response ("protein shake done, dishwasher done, no PT"), log what they mentioned and ask about the rest. Don't assume the unmentioned ones are false.

### Handling Multi-Day Gaps

If there are unlogged days between the last log entry and today, ask: "I see [date] through [date] aren't logged. Want to go through those, or just log today?" Respect the answer. Don't guilt-trip about gaps.

---

## Habit Configuration

Habits are defined in `habit-config.yaml`. The schema:

```yaml
# Habit Tracker Configuration

timezone: "America/Los_Angeles"   # IANA timezone for determining "today"
log_file: "habit-log.json"        # Path to the JSON log file (relative to config)
log_archive: "habit-log-archive.json"  # Path to archived entries
retention_days: 30                # Days to keep in active log before archiving

habits:
  - id: water_morning             # Unique key used in the log file
    name: "Water in the morning"  # Human-readable name
    description: "Drink water immediately upon waking"
    category: "nutrition"         # For grouping in check-ins and reports
    schedule: "daily"             # daily | weekdays | weekends | specific
    # schedule_days: ["mon", "wed", "fri"]  # Only if schedule is "specific"
    # threshold_note: ""          # Optional: what counts as "done" if non-obvious
    active: true                  # Set to false to pause without deleting

routines:
  - id: evening_routine
    name: "Evening Routine"
    description: "Nightly reset before bed"
    schedule: "daily"
    habits:                       # Habit IDs that belong to this routine
      - tidy_nursery
      - tidy_living_room
      - tidy_kitchen
      - run_dishwasher
      - set_up_coffee_maker
    # Routine habits are still tracked individually, but the routine
    # provides grouped check-in and aggregate streak reporting.
```

### Schedule Types

- **`daily`** — Every day.
- **`weekdays`** — Monday through Friday.
- **`weekends`** — Saturday and Sunday.
- **`specific`** — Only on listed days. Uses `schedule_days: ["mon", "tue", ...]`.

### Categories

Categories group habits during check-in and reporting. Common categories: `physical`, `nutrition`, `family`, `evening`, `morning`, `health`, `work`. The user defines their own.

### Routines

Routines are named groups of habits that logically belong together (e.g., "evening routine"). Each habit in a routine is still tracked individually, but the routine provides:
- A grouped check-in option ("Did you do your evening routine?" → then ask about specifics for any missed)
- Aggregate streak reporting ("Evening routine: 3 days complete, 2 partial")
- A useful abstraction for habits that feel like a single activity

---

## Logging Format

The log file is JSON with date keys and habit ID values:

```json
{
  "2026-03-13": {
    "water_morning": true,
    "oatmeal_10am": true,
    "pt_knee": false,
    "run_dishwasher": "covered",
    "tidy_nursery": true
  }
}
```

Three states:
- `true` — Done.
- `false` — Missed.
- `"covered"` — Someone else handled it.

### Log Maintenance

The `retention_days` config field controls how long entries stay in the active log. When running a check-in, if entries older than `retention_days` exist:

1. Move them to the `log_archive` file.
2. Keep the active log lean for faster reads and lower context consumption.

This happens automatically during check-in — no user action needed.

---

## Streak Calculation

A streak is the number of consecutive days a habit was completed (`true`). Rules:

- **`true` days build the streak.**
- **`false` days break the streak.**
- **`"covered"` days are neutral** — they don't break the streak, but they don't build it either. If the streak is water: ✅ ✅ ➖ ✅, the streak is 4 (covered day bridges).
- **Unlogged days are ambiguous.** Don't count them as missed. Report the streak as "X days (last logged: [date])" when there are gaps.
- **Schedule-aware.** A habit scheduled for "weekdays" shouldn't have its streak broken by an unlogged Saturday.

### Contribution Grid

When reporting streaks, show a visual grid for the last 14 days:

```
Water:    ■ ■ ■ ■ ■ □ ■ ■ ■ ■ □ ■ ■ ■  (12/14)
PT:       □ □ ■ □ □ □ □ ■ □ □ ■ □ □ □  (3/14)
Dishwash: ■ ■ □ ■ ■ ▪ ■ ■ □ ■ ■ ■ □ ■  (10/14, 1 covered)
```

Legend: ■ = done, □ = missed, ▪ = covered, · = not scheduled

### Visual Dashboard

When the user asks to *see* their habits ("show me my habits," "habit dashboard," "visualize my streaks"), generate an interactive HTML file. The text grid above is for inline check-in summaries; the dashboard is for deeper review.

**How to build it:**

1. Read `habit-config.yaml` for habit definitions, categories, schedules, and routines.
2. Read the log file for the last 14–30 days of data (user can request a different range).
3. Generate a single self-contained HTML file (inline CSS + JS, no external dependencies) and save it to the user's workspace.

**Dashboard requirements:**

- **Dark theme** — `#0d1117` background, GitHub-style color palette (green for done, blue for covered, dark gray for missed, dashed border for unlogged, subtle dot for not-scheduled).
- **Summary bar** at top — completion rate (done / scheduled days), total days logged, best current streak, covered count.
- **Category grouping** — habits grouped under category headers matching the config.
- **Contribution grid** — one row per habit, one cell per day. Each cell is a small colored square. Cells show a tooltip on hover with the date and status.
- **Schedule-aware rendering** — don't show a "missed" cell on a day the habit wasn't scheduled. Show it as "not scheduled" (distinct from unlogged).
- **Stats column** — `done/total` count to the right of each row. If there are covered days, show them separately (e.g., `4/7 +1c`).
- **Streak column** — current streak count to the right of stats. Green if active, gray if broken (0).
- **Routine aggregation** — if the config defines routines, show a summary row for each routine below its member habits. A routine day is "complete" if all member habits are done, "partial" if some are, "missed" if none are.

**What NOT to do:**

- Don't hardcode habit names, IDs, or categories. Read everything from the config.
- Don't use external CDNs, fonts, or scripts. The file must work offline.
- Don't include localStorage or sessionStorage. All data comes from the files.

**Example trigger phrases:** "show me my habits," "habit dashboard," "how am I doing on habits," "visualize streaks," "habit report."

---

## First-Time Setup

When no `habit-config.yaml` exists, walk the user through setup:

1. **Ask about categories.** "What areas of your life do you want to track habits for? Common ones: health, nutrition, fitness, family, evening routine, morning routine, work."

2. **Define habits per category.** For each category: "What specific habits do you want to track? For each one, I need: a name, a brief description, and whether it's daily or only certain days."

3. **Identify routines.** "Do any of these habits belong together as a routine? For example, an evening routine might group tidying, dishwasher, and coffee maker prep."

4. **Set timezone.** "What timezone are you in? This matters for determining what 'today' means."

5. **Generate config.** Write `habit-config.yaml` and create an empty `habit-log.json`.

6. **Confirm.** Show the user their config and ask if anything needs adjustment.

---

## Integration with Other Systems

The habit tracker is designed to work standalone, but it plays well with:

- **Daily planning sessions** — Run the check-in as step 1 of morning planning. The skill handles the flow; the planning system just needs to trigger it.
- **Evening reviews** — Run the check-in as a gate before closing the day. If habits haven't been logged, the skill catches it.
- **Daily cards / dashboards** — The `habit-log.json` file is machine-readable. The skill generates its own HTML dashboard on demand (see [Visual Dashboard](#visual-dashboard)), but external visualization systems can also read the log directly.
- **Coaching systems** — The streak data can feed into motivational systems. The skill reports streaks; what you do with that information is up to the broader system.

### Context Efficiency

This skill is designed for minimal context consumption:

- **The config file is small** (~1-2KB for most users) and only loaded when the skill triggers.
- **The log file uses a retention window** (default 30 days) so it doesn't grow unbounded.
- **The skill doesn't need to be in mandatory context.** It loads on-demand when habits come up, and unloads when it's done. This is the key difference from hardcoding habit logic in always-loaded system files.

---

## Continuous Improvement

This skill is actively developed. During any session where the skill is running, watch for friction — things that feel wrong, take too long, produce bad results, or don't match the user's expectations.

### Issue Capture Protocol

When you notice a problem during a check-in or habit-related interaction:

1. **Don't stop the session to fix it.** Finish the check-in or habit task first.
2. **Log the issue.** Append a one-liner to the issues file (configured in `issues_file`, defaults to `skill-issues.md` next to the config). Format:
   ```
   - YYYY-MM-DD: [brief description of what went wrong or felt off]
   ```
3. **Move on.** The issue will be addressed in a dedicated skill improvement session, not mid-workflow.

### What Counts as an Issue

- Check-in protocol asked about a habit on the wrong day (schedule bug)
- Streak calculation produced an incorrect or confusing result
- Config schema was missing a field the user needed
- The skill triggered when it shouldn't have, or didn't trigger when it should have
- A habit ID mismatch between config and log (normalization gap)
- The check-in felt too slow, too repetitive, or too rigid
- Any moment where the user had to correct the skill's behavior

### Improvement Cycle

Issues accumulate in the issues file. In a dedicated session (not during a check-in), review them, make changes to the skill, and clear resolved issues. If the skill is published as a repo, batch improvements into a version bump.

---

## Context Compaction Recovery

If context compaction occurs during a session where habits were being discussed:

1. **Re-read this SKILL.md.**
2. **Re-read `habit-config.yaml`** to restore habit definitions.
3. **Check `habit-log.json`** for today's date to see what was already logged.
4. **Don't re-ask about habits already logged.** If today's entry exists and has values, those were confirmed by the user.

---

## Reference Files

- `references/methodology.md` — Design principles behind this skill, including context engineering rationale and the "never assume false" origin story.
- `templates/habit-config.yaml` — Starter config with examples and full schema documentation.
- `scripts/init-habits.sh` — Scaffolding script for first-time setup.
