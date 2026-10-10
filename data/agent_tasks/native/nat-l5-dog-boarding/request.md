I'm writing the booking backend for a dog-boarding kennel as a Jac service (`app.jac`). Kennel runs are `Run` nodes on `root` with a `Size`; each booked stay is a `Stay` node hosted by its run (`Hosts` edge). A stay with `start=10, nights=3` occupies nights 10, 11 and 12. `add_run` already exists. I need four `walker:pub` endpoints (REST `POST /walker/<name>`, body → `has` fields, response in `data.reports[0]`); state must persist in the graph between requests.

1. **`book_stay`** — body `{"dog": str, "size": "SMALL"|"MEDIUM"|"LARGE", "start": int, "nights": int}`.
   - `"bad size"` if the size isn't a `Size` name; `"bad dates"` if `nights < 1` (check in that order). Failures are reported as `{"ok": false, "reason": ...}`.
   - A dog fits any run whose size is **at least** the dog's size. Pick the **smallest** fitting size that has a run free for every night of the stay (no overlap with any stay already in that run); among runs of that size pick the lowest `code`.
   - No such run → `{"ok": false, "reason": "no vacancy"}`. Otherwise add the stay to that run and report `{"ok": true, "run": <code>}`.
2. **`check_out`** — body `{"dog": str}`. Delete every stay of that dog in every run; report the number removed.
3. **`occupancy`** — body `{"night": int}`. Report the sorted list of `"<run code>:<dog>"` for stays that cover that night.
4. **`vacancy`** — body `{"start": int, "nights": int}`. Report a dict with all three size names mapping to how many runs of that size are free for the whole period.
