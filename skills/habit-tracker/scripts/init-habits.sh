#!/usr/bin/env bash
#
# init-habits.sh — Scaffold a new habit tracking setup
#
# Usage:
#   ./init-habits.sh <directory> [--timezone TIMEZONE]
#
# Creates habit-config.yaml (from template) and an empty habit-log.json
# in the specified directory.

set -euo pipefail

# --- Argument parsing ---

TIMEZONE=""
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --timezone)
            TIMEZONE="$2"
            shift 2
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

if [ ${#POSITIONAL_ARGS[@]} -lt 1 ]; then
    echo "Usage: $0 <directory> [--timezone TIMEZONE]"
    echo ""
    echo "  directory     Path where habit tracking files will be created"
    echo "  --timezone TZ IANA timezone (e.g., America/New_York). Default: America/Los_Angeles"
    exit 1
fi

TARGET_DIR="${POSITIONAL_ARGS[0]}"
TIMEZONE="${TIMEZONE:-America/Los_Angeles}"

# --- Locate skill root (where templates live) ---

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TEMPLATES_DIR="$SKILL_ROOT/templates"

if [ ! -d "$TEMPLATES_DIR" ]; then
    echo "Error: Templates directory not found at $TEMPLATES_DIR"
    exit 1
fi

# --- Portable sed -i ---

sed_inplace() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "$@"
    else
        sed -i "$@"
    fi
}

# --- Create target directory ---

mkdir -p "$TARGET_DIR"

# --- Copy config template ---

if [ -f "$TARGET_DIR/habit-config.yaml" ]; then
    echo "habit-config.yaml already exists in $TARGET_DIR — skipping."
    echo "Delete it first if you want to start fresh."
else
    cp "$TEMPLATES_DIR/habit-config.yaml" "$TARGET_DIR/habit-config.yaml"
    sed_inplace "s|America/Los_Angeles|$TIMEZONE|" "$TARGET_DIR/habit-config.yaml"
    echo "Created: $TARGET_DIR/habit-config.yaml"
fi

# --- Create empty log file ---

if [ -f "$TARGET_DIR/habit-log.json" ]; then
    echo "habit-log.json already exists — skipping."
else
    echo "{}" > "$TARGET_DIR/habit-log.json"
    echo "Created: $TARGET_DIR/habit-log.json"
fi

echo ""
echo "--- Habit tracking scaffolded ---"
echo ""
echo "Next steps:"
echo "  1. Edit $TARGET_DIR/habit-config.yaml to define your habits"
echo "  2. Start a session and say: 'Let's check in on habits'"
echo "     The skill will find your config automatically."
echo ""
echo "Or: ask your AI assistant to 'set up habit tracking' and"
echo "it will walk you through defining habits interactively."
