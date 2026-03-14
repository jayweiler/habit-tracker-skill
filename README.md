# Habit Tracker Skill

A daily habit tracking skill for Claude Code and Cowork. Handles check-ins, JSON logging, streak tracking, and flexible scheduling — with any set of user-defined habits.

## Install

### Cowork (Claude Desktop)

Download the `.skill` file from [Releases](../../releases) and open it in Cowork, or copy the `skills/habit-tracker/` directory into your Cowork skills folder.

### Claude Code

```bash
# Clone the repo
git clone https://github.com/jayweiler/habit-tracker-skill.git

# Copy the skill to your Claude Code skills directory
cp -r habit-tracker-skill/skills/habit-tracker ~/.claude/skills/
```

## Quick Start

After installing, start a session and say:

> "Set up habit tracking"

The skill will walk you through defining your habits, categories, routines, and timezone. It creates a `habit-config.yaml` and `habit-log.json` in your workspace.

Or run the init script directly:

```bash
./skills/habit-tracker/scripts/init-habits.sh /path/to/your/workspace --timezone America/New_York
```

## Usage

Once set up, the skill triggers on natural language:

- "Let's check in on habits"
- "Log my habits for today"
- "How are my streaks?"
- "Did I do my PT yesterday?"
- Morning/evening check-in flows

## Features

- **Config-driven** — your habits, your categories, your schedule
- **Three tracking states** — done, missed, covered (someone else did it)
- **Flexible scheduling** — daily, weekdays, weekends, or specific days
- **Routine grouping** — group related habits (e.g., "evening routine")
- **Streak tracking** — with schedule-aware calculation and visual grids
- **Automatic log maintenance** — 30-day retention with archival
- **Context efficient** — loads on-demand, not every session

## File Structure

```
skills/habit-tracker/
├── SKILL.md                    # Main skill instructions
├── references/
│   └── methodology.md          # Design principles and origin story
├── scripts/
│   └── init-habits.sh          # Setup scaffolding script
└── templates/
    └── habit-config.yaml       # Starter config with full schema docs
```

## How It Works

The skill is pure instructions — no code to execute, no dependencies to install. It tells the AI assistant how to:

1. Find and read your `habit-config.yaml`
2. Run a check-in protocol (asking about each habit individually)
3. Log completions to `habit-log.json`
4. Calculate and report streaks
5. Maintain the log file (archiving old entries)

The AI does all the work. The skill just makes sure it does it correctly and consistently.

## License

MIT
