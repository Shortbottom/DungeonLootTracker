# Dungeon Loot Tracker

A minimal, dependency-free Retail addon that automatically logs your own loot
messages while inside a party dungeon. The latest 200 messages are saved per
character across reloads, with dungeon name and timestamp. Messages retain the
item links and quantities provided by the game.

## Commands

- `/dlt` or `/dungeonloottracker`: toggle the scrollable loot log.
- `/dlt clear`: clear this character's log.
- `/dlt help`: show command help.

Drag the window to move it; close it with its close button or Escape.
Install this folder as `Interface/AddOns/DungeonLootTracker` and enable the addon.
The interface version remains `120100` from the previous addon.

This is a basic loot-message log, not bag tracking: it excludes raids, outdoor
loot, other players, money, and currency events. Restricted messages are skipped.
There are no selling, filtering, minimap, or run-summary features yet.

## Saved data and backup

`backup/before-rebuild` preserves the previous addon, uncommitted source changes,
and bundled libraries. `rebuild/minimal` contains this replacement.
The old `dltDB` and `DLTRecordings_DB` names remain declared to retain saved data;
the replacement does not read or modify them. New data uses `DLTMinimalDB`.
Git backs up addon files, not the game's separate WTF/SavedVariables directory.

## Manual smoke check

1. Enable the addon and reload; check for Lua errors.
2. Run `/dlt`, move the window, and try its close button and Escape.
3. Loot an item in a dungeon. Verify its message, quantity, and dungeon name.
4. Verify another player's loot and outdoor loot do not enter the log.
5. Reload and verify the log persists; test scrolling and `/dlt clear`.

Only `Main.lua` loads from the TOC. Packaging requires no external libraries.
