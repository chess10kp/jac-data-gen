`python/app/models.py` is the Beanie data layer of a Telegram medication-reminder bot (helpers in `python/app/helpers.py`, model tests in `python/tests/models/`). Could you port that data layer to Jac as `reminders.jac`, storing everything in the graph?

- Nodes: `User` (`username`, `tg_user_id: int`, `tg_chat_id: int`) on `root`; `Medication` (`name`, `notification_time` as "HH:MM", `deleted: bool = False`); `Notification` (`sent_at` as an ISO-8601 string, `was_taken: bool = False`). Skip the Telegram message-id fields.
- Edges instead of `Link`s: `User -[Takes]-> Medication -[Notified]-> Notification`.
- Port `is_time_right_format(time_string) -> bool` from helpers as a plain function.

Walkers (spawned on `root`):
- `register_user(username, tg_user_id, tg_chat_id)` → `{"ok": True}`, or `{"error": ...}` if the username is taken.
- `add_medication(tg_user_id, name, notification_time)` → medication dict `{"id", "name", "notification_time", "deleted"}`; `{"error": ...}` for an unknown user or a time that fails `is_time_right_format`.
- `get_medications(tg_user_id)` and `get_medications_ready_for_notifications(tg_user_id, at)` — lists of medication dicts, deleted ones excluded, sorted by `notification_time`; the second keeps only those with `notification_time <= at`.
- `delete_medication(medication_id)` — soft delete (sets `deleted`), reports `True`/`False`.
- `record_notification(medication_id, sent_at, was_taken=False)` → notification dict `{"id", "medication" (name), "medication_id", "sent_at", "was_taken"}` (or `None` if no such medication); `mark_taken(notification_id)` → `True`/`False`.
- `get_taken_notifications_for_time_period(tg_user_id, start, end)` — that user's taken notifications with `start <= sent_at <= end`, ascending by `sent_at`.
- `get_notification_for_current_day(medication_id, day)` — first notification of that medication whose date is `day` ("YYYY-MM-DD"), else `None`.
- `get_not_taken_notifications_for_current_day(day)` — every not-taken notification on that date.

`jac check` must be clean.
