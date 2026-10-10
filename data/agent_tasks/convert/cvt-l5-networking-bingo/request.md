hey — `python/api/` is the backend of a little meetup "networking bingo" app (FastAPI + ODMantic/Mongo). Could you redo it as a Jac service in `main.jac`? jac.toml is already set up with it as the entry point.

Each ODMantic model (`UserId`, `UserModel` in `auth/models.py`, `Attribute`, `BingoBoard` in `bingo/models.py`) should become a node on the graph, and each route handler a public walker with the same name, taking the path/body params as walker fields:

- `hc()` → `"server is running"`
- `add_or_get_user(name, discord)` → `{"ok": true, "user_id": n}` — ids come from the `UserId` counter (1, 2, 3, …); an already-registered name+discord gets its old id back
- `get_attr(user_id)`, `set_attr(user_id, attribute)`
- `get_bingo_board(user_id)`, `new_bingo_board(user_id, board)`
- `add_bingo(user_id, gave_id)` — `gave_id` is the `user_id` from the request body in the Python version

Report exactly the same `{"ok": ..., ...}` dicts the model classmethods return, Korean messages included. Please keep the game logic in `add_bingo_to_board` exactly as it behaves now, even the parts that look odd — the frontend depends on it and we'll fix it separately.

Must run with `jac start main.jac` and pass `jac check`.
