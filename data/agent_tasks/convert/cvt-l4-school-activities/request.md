hey — `python/src/` is a small FastAPI + Beanie app for a high school's extracurricular activities (models in `models.py`, routes in `app.py`). can you redo the backend in Jac as `activities.jac`, using the graph instead of Mongo?

graph: `Club` nodes on root (`name`, `description`, `coordinator_id`, `status` default "pending"), each club hosts `Event`s via a `Hosts` edge (`name`, `description`, `schedule`, `max_participants`, `coordinator_id`, `status` default "pending"), and each event has `Registration` nodes via a `HasRegistration` edge (`student_id` = the student's email, `status` "active"/"cancelled", `registered_at`, `cancelled_at`).

walkers (spawn on root):
- `create_club(name, description, coordinator_id)` – club names are unique (400 otherwise); reports `{"id", "name", "status"}`
- `create_event(club_name, name, description, schedule, max_participants)` – 404 if the club doesn't exist; reports `{"id", "name", "status"}`
- `approve_event(name)` – sets status to "approved"
- `get_activities()` – same dict as `GET /activities`: approved events keyed by name → `{"description", "schedule", "max_participants", "participants" (count of active registrations), "_id"}`
- `signup_for_activity(activity_name, email)` and `unregister_from_activity(activity_name, email)` – same rules, messages and errors as the FastAPI handlers (unregister marks the registration cancelled + sets `cancelled_at`, it doesn't delete it)

errors: report `{"status": <code>, "detail": "<same text>"}` instead of raising. needs to pass `jac check`.
