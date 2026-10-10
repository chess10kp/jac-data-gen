This is a small event-planner backend written with FastAPI + Beanie (Mongo) — see `python/` (models in `python/models/`, routes in `python/routes/`, the Beanie wrapper in `python/database/connection.py`, and the pytest suite in `python/tests/`). We want it as a Jac service so we can stop running Mongo.

Please write `main.jac` (already the entry point in `jac.toml`) with `User` and `Event` nodes stored on the graph, and one public walker per route handler, keeping the handler names:

- `sign_new_user(email, password)` → `{"message": "User created successfully"}`; same email twice is an error. Don't store the raw password — a one-way hash is fine (no bcrypt available).
- `get_all_events()` → list of events
- `get_event_by_id(event_id)`
- `create_event(user, title, image, description, tags, location)` → `{"message": "Event created successfully", "id": ...}`; the event's `creator` is `user`
- `update_event(event_id, user, ...)` — partial update like the Beanie version (only fields that are passed change), returns the updated event
- `delete_event(event_id, user)` → `{"message": "Event deleted successfully"}`
- `delete_all_events(user)` → `{"message": "All events deleted successfully"}`

We're dropping the JWT login for now, so skip `sign_in_user` and just take the acting user's email as the `user` argument wherever the Python code used the token — but keep the "only the creator can edit/delete" rule. Events should be reported as dicts with `id` (the node's Jac id), `title`, `image`, `description`, `tags`, `location`, `creator`. Wherever the Python raises an HTTPException, report `{"error": "<same detail text>"}` instead.

It needs to boot with `jac start main.jac` and pass `jac check`.
