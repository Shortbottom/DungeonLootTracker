# Before release

- [x] Remove the temporary Recover loot feature: its button, `/dlt recover`
  command, confirmation dialog, recovery implementation, recovery-only tests,
  and user documentation. It exists only to repair development-era records.
  Preserve normal loot tracking, saved-record compatibility, and sale safeguards.

- [x] Prepare release notes for 0.1.0.
- [x] Run the Lua regression suite and validate release configuration.
- [ ] Push annotated tag 0.1.0 and verify the packaging workflow and release assets.
