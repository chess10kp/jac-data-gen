I'm building the backend for a small bike-share scheme as a Jac service (`app.jac`, served with `jac start app.jac`). Stations, bikes and riders are already modelled, and `add_station` / `add_bike` work. I need three more endpoints, written as **`walker:pub`** walkers (they're called over REST at `POST /walker/<name>`; the request body fills the walker's `has` fields, and the client reads the walker's single `report` from `data.reports[0]`). All state lives in the graph under `root`, so it must persist from one request to the next.

1. **`rent_bike`** — body `{"station": <code>, "rider": <name>, "minute": <int>}`.
   - Unknown station → report `{"ok": false, "reason": "unknown station"}`.
   - A rider can only have one bike at a time → `{"ok": false, "reason": "already riding"}`.
   - No bike docked there → `{"ok": false, "reason": "no bikes"}`.
   - Otherwise hand out the docked bike with the **lowest `km`** (ties: lowest serial), undock it, and record it on the rider (create the `Rider` node on `root` on first use) with a `Riding` edge whose `since` is `minute`. Report `{"ok": true, "bike": <serial>}`.
   - Check the conditions in the order listed.
2. **`return_bike`** — body `{"station": <code>, "rider": <name>, "km": <float>}`.
   - Unknown station → `"unknown station"`; rider with no bike → `"not riding"`; station already at capacity → `"station full"` (the rider keeps the bike).
   - Otherwise add `km` to the bike's odometer, remove the `Riding` edge, dock the bike at that station and report `{"ok": true, "bike": <serial>}`.
3. **`network_status`** — no body fields. Visit every station and report one list, sorted by station code, of `{"code": ..., "bikes": <docked count>, "free": <capacity - docked>}`.
