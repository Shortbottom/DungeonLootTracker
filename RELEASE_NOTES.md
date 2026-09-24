# Dungeon Loot Tracker 0.1.0

Initial release of the rebuilt, dependency-free Retail addon.

- Automatically record dungeon and raid visits, difficulty, entry/finish times,
  and duration, with manual start/stop controls.
- Browse ten runs per page and open a run to inspect its item loot and sales.
- Track looted money and confirmed vendor income per run, plus all-run earnings.
- Sell only tracked quantities, preserving pre-existing inventory quantities.
- Apply quality, equipment, and reagent filters to manual and automatic sales.
- Limit sales to eleven stacks per batch by default, with manual continuation
  and an optional unlimited mode requiring a buyback warning confirmation.
- Preserve window position, size, and options across sessions.
- Delete individual runs or confirm clearing recorded data while retaining options.
- Migrate existing quantity fields to QtySold and QtyRemaining.

The temporary development-only Recover loot tool is not included.

## Notes

Auto-sell is off by default. Mixed stacks require a free bag slot for splitting.
Loot quantities consumed, equipped, mailed, or banked may lose sale eligibility.
Income is attributed only to sales confirmed through the addon; external sales
and vendor buybacks are not reconciled. Interrupted sessions have incomplete
durations. This release targets Retail interface 120100.
