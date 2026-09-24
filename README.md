# Dungeon Loot Tracker

A dependency-free Retail addon for dungeon and raid history. Each visit records
its name, instance type, difficulty, entry time, finish time, duration, loot,
looted money, and income from sales made through this addon. Data is saved per
character. Existing legacy loot messages remain saved but cannot be assigned
retroactively to a run or sold through the addon.

## Recording and history

Entering a dungeon or raid starts a recording automatically. Leaving finishes it;
a return visit starts a new record. Changing instance or difficulty also starts a
new record. `/dlt stop` ends recording early; the actual exit time is still saved
when you leave. There is no boss-completion detection yet.

The recording button shows **Stop run** while recording and **Start run** otherwise.
Start begins a fresh record in the current dungeon or raid after a manual stop,
preserving the previous record. The button controls the current recording even
while browsing older history. Outside a dungeon or raid, Start explains where
recording is available.

UI reloads resume the current record. A new login closes an unfinished record at
its last known timestamp, labels its duration incomplete, and leaves its actual
exit time unknown. If you log in inside an instance, a new record starts then;
the addon cannot reconstruct time or loot while it was offline.

Open `/dlt` for a list of visits, newest first, with 10 runs per page and Previous/
Next controls. Each clickable, single-line row shows the dungeon or raid name,
duration, and total earned (looted money plus confirmed sales). The fixed footer
shows total earnings across all recorded runs, regardless of the current page.
Click a row to view entry time, difficulty, and
its loot and sale history; use **Back to runs** to return to the list. Sell,
Delete, and Recover actions are shown in the selected run's detail view.
**Delete run** removes the displayed record and its loot and sale history. If it
was the current run, recording stays stopped until you click Start run or enter
another visit. Deletion is unavailable during a sale pass.
Money is parsed from localized loot-money messages, excluding repairs, trading,
and other balance changes. Individual money messages are hidden from item details;
their amounts appear in Looted Money. Unrecognized messages are saved for diagnosis
and flagged as missing from the total. Item links and quantities remain visible.

## Selling and options

Open a merchant, select a completed run, and click **Sell loot** (or `/dlt sell`).
Only outstanding quantities recorded for that run are eligible. For example,
10 cloth owned before entry plus 6 looted cloth results in selling **6**, keeping
**10**. Mixed stacks are split into an empty general-purpose bag slot first. If
there is no suitable slot, the mixed stack is kept. Do not rearrange bags or use
other vendor automation during a sale pass.

Options are available through the **Options** button or `/dlt options`:

- Auto-sell completed runs when opening a merchant (off by default).
- Open history when entering a dungeon or raid (off by default).
- Allow more than 11 sales per batch (off by default; requires confirmation that
  some sold items may no longer be available to buy back). Quantity limits and
  item filters still apply.
- Allowed item qualities: Poor, Common, Uncommon, Rare, Epic (Poor only by default).
- Keep weapons and armor (on by default).
- Keep crafting reagents (on by default).

The same filters apply to manual and automatic sales. Quest items, equipment-set
items, refundable items, containers with loot, locked items, items with no vendor
value, and qualities above Epic are always kept. Enable Common and disable
Keep crafting reagents if you want cloth sold. Auto-sell checks all completed
records with outstanding loot, not just the record currently displayed.

Sales are processed one stack at a time and credited only after the matching
quantity leaves the bags and the expected vendor money arrives. DLT makes at most
11 sale attempts per automatic merchant visit or deliberate manual batch by
default. Each stack counts as one sale, regardless of its quantity. At the limit,
check Buyback before clicking Sell loot again to sell up to another 11 stacks.
Each completed batch needs a new click; clicks during an active batch do nothing.
Each recorded item has an `isSold` flag: `0` until its full recorded quantity has
been confirmed sold, then `1`. Later passes skip flagged items. The separate
`QtySold` quantity counter and `QtyRemaining` preserve partial-stack accounting;
old `sold` and `remaining` fields migrate automatically on load. Failed sales and
items consumed or moved elsewhere are not marked sold.
Later batches may remove earlier items from Buyback. Sales by other addons or manual bag clicks
are outside this limit.
Failed or
ambiguous sales stop the queue without claiming unverified income. Other sales,
repairs, vendor buybacks, auction-house sales, and trades are not attributed to
runs. Closing the merchant stops further sales; an already-sent transaction can
still be confirmed. Combat and repair mode prevent new sales.

Quantities are matched by item variant. Detected bag losses retire tracked
quantities first, conservatively keeping pre-existing stock. Used, equipped,
mailed, or banked items can therefore lose sale eligibility. Later unrelated
acquisitions do not restore that eligibility. Activity while the addon is disabled
cannot be reconstructed. History has no automatic deletion limit.

## Commands

If an older version incorrectly retired loot during a loading screen, select the
affected run and use **Recover loot** or `/dlt recover`. The confirmation warns
that consumed or replaced loot cannot be distinguished from pre-existing items.
Recovery restores at most the recorded unsold amount currently in the bags,
excluding quantities reserved for other runs. It does not sell anything or
change filters. Verify the record and filters before selling recovered loot.

- `/dlt` or `/dungeonloottracker`: toggle history.
- `/dlt stop`: finish the current recording.
- `/dlt sell`: sell eligible loot from the selected completed run.
- `/dlt recover`: confirm recovery of the selected completed run's sale quantities.
- `/dlt options`: open auto-sell and filter options.
- `/dlt clear`: show a Yes/No confirmation to delete all recorded data while
  preserving options. Yes also clears the old recordings database; No or Escape cancels.
  Recording stays stopped until Start run or the next visit. Clearing is blocked
  during a sale pass.
- `/dlt help`: show help.

Drag the history window to move it; close either window with its close button or
Escape. Drag the bottom-right handle to resize it (minimum 620 by 440). Its size
and position are saved per character across reloads and logins, and are
preserved by `/dlt clear`. Install this folder as `Interface/AddOns/DungeonLootTracker`. The interface
version remains `120100` from the original addon.

## Backup and saved data

`backup/before-rebuild` preserves the old addon, uncommitted changes, and libraries.
`rebuild/minimal` contains the replacement. The old `dltDB` and `DLTRecordings_DB`
names remain declared. A confirmed `/dlt clear` clears `DLTRecordings_DB` and
current recorded data, preserving `dltDB` and current options. New data uses `DLTMinimalDB`. Git does not
back up the game's separate WTF/SavedVariables directory.

## Validation

Run `python tests/run.py` with `lupa` installed to execute the Lua 5.1 tests.
They cover run transitions, reloads, manual stops, interrupted sessions, localized
parsing, quantity protection, multiple runs, filters, and sale failure handling.

In WoW, verify dungeon and raid entry/exit, difficulty, reload persistence, money
messages in your locale, window controls, and a merchant sale with 10 existing
plus 6 looted cloth. Also verify full bags, filter changes, and merchant closure.
Mock tests do not substitute for in-game API and visual testing.
