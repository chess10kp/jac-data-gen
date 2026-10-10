We run the lost-property desk for a tram operator and I'm moving it to a Jac service (`app.jac`). Found items are `Item` nodes on `root` (logged with the existing `log_item` function, which hands back tags like `LF-3`); when the owner collects one we attach a `Claim` node to it with a `ClaimedBy` edge. Please add these `walker:pub` endpoints (`POST /walker/<name>`, body → `has` fields, response read from `data.reports[0]`); everything must persist in the graph between requests:

1. **`search`** — body `{"category": <Category name>, "color": str, "since_day": int}`. Visit the **unclaimed** items and report the tags of those whose category matches exactly, whose colour matches **case-insensitively**, and that were found on or after `since_day`. Sort newest first (`found_day` descending), ties by tag ascending. An unknown category name just matches nothing.
2. **`claim`** — body `{"tag": str, "name": str}`. Unknown tag → `{"ok": false, "reason": "unknown item"}`; already claimed → `{"ok": false, "reason": "already claimed"}`; otherwise attach a new `Claim(name=...)` and report `{"ok": true}`.
3. **`expire`** — body `{"today": int, "keep_days": int}`. Unclaimed items kept **longer** than `keep_days` (`today - found_day > keep_days`) are donated: delete their nodes. Report the sorted list of donated tags. Claimed items are never donated.
4. **`stats`** — no body fields. Report a dict with one entry per `Category` name (all five, even if zero): `{"open": <unclaimed count>, "claimed": <claimed count>}`.

Don't change `log_item` or the node/edge declarations.
