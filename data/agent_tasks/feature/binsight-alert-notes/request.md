Dining hall managers want to leave notes on alerts ("called facilities", "bin re-weighed, false alarm") so the next shift knows what happened. Right now an `Alert` is just a node on root with no history.

Could you add notes to the graph model?

- A new node type `AlertNote` in `domain/nodes.jac` with `note_id`, `author`, `text`, `created_at` (all strings). Each note should hang off the alert it belongs to (add an edge type for it in `domain/edges.jac`), not off root.
- A walker `AddAlertNote` in `walkers/alert_walkers.jac` taking `alert_id, note_id, author, text, created_at`. It should report `{"alert_id": ..., "added": bool, "note_count": int}` where `note_count` is how many notes that alert has afterwards. Don't add anything if the alert doesn't exist, if the text is blank, or if a note with that `note_id` is already on the alert (retries from the UI).
- A walker `ListAlertNotes(alert_id)` that reports `{"alert_id": ..., "found": bool, "notes": [{"note_id", "author", "text", "created_at"}, ...]}` with notes oldest first.

Both should be public like the other alert walkers. Existing alert behaviour shouldn't change.
