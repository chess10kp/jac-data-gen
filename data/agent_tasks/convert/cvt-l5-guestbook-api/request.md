I have a tiny FastAPI + Mongo guestbook service in `python/` (ODMantic model in `python/app/model.py`, routes in `python/app/api.py`, and their end-to-end tests in `python/test_e2e.py`). I'd like to drop Mongo/FastAPI and run it as a Jac service instead.

Can you rewrite it as `main.jac` (the project's entry point, already set up in `jac.toml` as a service)?

- Store guestbook entries as `Entry` nodes on the graph (fields `name`, `entry`, `date`), not in an external DB.
- Each route becomes a public walker with the same name as the Python handler: `welcome`, `retrieve_entries`, `add_entry` (takes `name` and `entry`), and `delete_entry` (takes `id`).
- Keep the response bodies the same as the Python app: the welcome message, `{"entries": [...]}` where each entry has `id`, `name`, `entry`, `date`, `{"message": "New entry added with ID: <id>"}` and `{"message": "Entry deleted successfully"}` (deleting an unknown id still returns that). Use the node's Jac id as the entry id.

It should start with `jac run --serve main.jac` and `jac check` should be clean.
