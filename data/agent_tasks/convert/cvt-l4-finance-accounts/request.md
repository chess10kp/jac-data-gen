Olá! This is a little FastAPI + Beanie finance API (`python/models.py` and the routers in `python/endpoints/`). I'd like the users / categories / accounts part rewritten in Jac as `finance.jac`, with the data living in the graph rather than Mongo. Skip transactions for now.

Keep the Portuguese field names. Model it as a graph: `User` nodes on `root` (`nome`, `email`, `senha_hash`), and each user's `Category` (`nome`) and `Account` (`nome`, `tipo`, `saldo_inicial: float`) nodes connected from the user through typed edges `HasCategory` and `Owns` (instead of the `Link[User]` fields).

Walkers (spawned on `root`), named after the route handlers:

- `create_user(nome, email, senha)` → `{"id", "nome", "email", "senha_hash"}`, where the hash is `"hashed_" + senha` like the Python code; a duplicate email gives `{"status": 400, "detail": "Email já cadastrado"}`.
- `create_category(nome, user_id)`, `get_categories(user_id="", limit=10, skip=0)`, `get_category(cat_id)`, `update_category(cat_id, nome=None)`, `delete_category(cat_id)`.
- `create_account(nome, tipo, saldo_inicial, usuario_id)`, `get_accounts(limit=10, skip=0)`, `get_account(acc_id)`, `update_account(acc_id, nome=None, tipo=None, saldo_inicial=None)`, `delete_account(acc_id)`.

Category dicts are `{"id", "nome", "user_id"}`, account dicts `{"id", "nome", "tipo", "saldo_inicial", "usuario_id"}`; ids are node `jid`s. List walkers report one list (paged with skip/limit, in creation order; `get_categories` filters by user when `user_id` is given). Updates only touch fields that were passed. Deletes report `{"status": 204}`. Where the API raises `HTTPException`, report `{"status": <code>, "detail": <same Portuguese message>}` instead ("Usuário vinculado não encontrado", "Usuário não encontrado", "Categoria não encontrada", "Conta não encontrada").

Heads-up: `skip` is a reserved word in Jac, so you'll need the backtick escape for that field. Make sure `jac check` is clean.
