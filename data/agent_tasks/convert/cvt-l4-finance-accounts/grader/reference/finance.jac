"""Personal-finance backend: users own categories and bank accounts.

Beanie documents -> nodes; the `Link[User]` back-references become typed edges
from the owning User (User -[HasCategory]-> Category, User -[Owns]-> Account);
each FastAPI route handler becomes a walker spawned on root. HTTPExceptions are
reported as {"status": <code>, "detail": <message>}.
"""

import uuid;

node User {
    has nome: str;
    has email: str;
    has senha_hash: str;

    def view -> dict[str, any] {
        return {"id": jid(self), "nome": self.nome, "email": self.email, "senha_hash": self.senha_hash};
    }
}

node Category {
    has nome: str;
}

node Account {
    has nome: str;
    has tipo: str;
    has saldo_inicial: float = 0.0;
}

edge HasCategory: User --> Category {}
edge Owns: User --> Account {}

def find_user(user_id: str) -> User | None {
    for u in [root -->[?:User]] {
        if jid(u) == user_id {
            return u;
        }
    }
    return None;
}

def category_owner(c: Category) -> User {
    return [c <-:HasCategory:<-][0];
}

def account_owner(a: Account) -> User {
    return [a <-:Owns:<-][0];
}

def all_categories -> list[Category] {
    return [c for u in [root -->[?:User]] for c in [u ->:HasCategory:->]];
}

def all_accounts -> list[Account] {
    return [a for u in [root -->[?:User]] for a in [u ->:Owns:->]];
}

def category_view(c: Category) -> dict[str, any] {
    return {"id": jid(c), "nome": c.nome, "user_id": jid(category_owner(c))};
}

def account_view(a: Account) -> dict[str, any] {
    return {"id": jid(a), "nome": a.nome, "tipo": a.tipo, "saldo_inicial": a.saldo_inicial,
            "usuario_id": jid(account_owner(a))};
}

def not_found(detail: str) -> dict[str, any] {
    return {"status": 404, "detail": detail};
}

def page(items: list[any], offset: int, limit: int) -> list[any] {
    return items[offset:offset + limit];
}

# ---------------------------------------------------------------- users
walker create_user {
    has nome: str;
    has email: str;
    has senha: str;

    can create with Root entry {
        if any(u.email == self.email for u in [-->[?:User]]) {
            report {"status": 400, "detail": "Email já cadastrado"};
            return;
        }
        u = here ++> User(nome=self.nome, email=self.email, senha_hash=f"hashed_{self.senha}");
        report u.view();
    }
}

# ---------------------------------------------------------------- categories
walker create_category {
    has nome: str;
    has user_id: str;

    can create with Root entry {
        u = find_user(self.user_id);
        if u is None {
            report not_found("Usuário vinculado não encontrado");
            return;
        }
        c = Category(nome=self.nome);
        u +>:HasCategory:+> c;
        report category_view(c);
    }
}

walker get_categories {
    has user_id: str = "";
    has limit: int = 10;
    has `skip: int = 0;

    can list_all with Root entry {
        if self.user_id {
            u = find_user(self.user_id);
            cats = [c for c in [u ->:HasCategory:->]] if u else [];
        } else {
            cats = all_categories();
        }
        report [category_view(c) for c in page(cats, self.skip, self.limit)];
    }
}

walker get_category {
    has cat_id: str;

    can fetch with Root entry {
        hits = [c for c in all_categories() if jid(c) == self.cat_id];
        report category_view(hits[0]) if hits else not_found("Categoria não encontrada");
    }
}

walker update_category {
    has cat_id: str;
    has nome: str | None = None;

    can patch with Root entry {
        hits = [c for c in all_categories() if jid(c) == self.cat_id];
        if not hits {
            report not_found("Categoria não encontrada");
            return;
        }
        if self.nome is not None {
            hits[0].nome = self.nome;
        }
        report category_view(hits[0]);
    }
}

walker delete_category {
    has cat_id: str;

    can remove with Root entry {
        hits = [c for c in all_categories() if jid(c) == self.cat_id];
        if not hits {
            report not_found("Categoria não encontrada");
            return;
        }
        del hits[0];
        report {"status": 204};
    }
}

# ---------------------------------------------------------------- accounts
walker create_account {
    has nome: str;
    has tipo: str;
    has saldo_inicial: float;
    has usuario_id: str;

    can create with Root entry {
        u = find_user(self.usuario_id);
        if u is None {
            report not_found("Usuário não encontrado");
            return;
        }
        a = Account(nome=self.nome, tipo=self.tipo, saldo_inicial=self.saldo_inicial);
        u +>:Owns:+> a;
        report account_view(a);
    }
}

walker get_accounts {
    has limit: int = 10;
    has `skip: int = 0;

    can list_all with Root entry {
        report [account_view(a) for a in page(all_accounts(), self.skip, self.limit)];
    }
}

walker get_account {
    has acc_id: str;

    can fetch with Root entry {
        hits = [a for a in all_accounts() if jid(a) == self.acc_id];
        report account_view(hits[0]) if hits else not_found("Conta não encontrada");
    }
}

walker update_account {
    has acc_id: str;
    has nome: str | None = None;
    has tipo: str | None = None;
    has saldo_inicial: float | None = None;

    can patch with Root entry {
        hits = [a for a in all_accounts() if jid(a) == self.acc_id];
        if not hits {
            report not_found("Conta não encontrada");
            return;
        }
        a = hits[0];
        if self.nome is not None {
            a.nome = self.nome;
        }
        if self.tipo is not None {
            a.tipo = self.tipo;
        }
        if self.saldo_inicial is not None {
            a.saldo_inicial = self.saldo_inicial;
        }
        report account_view(a);
    }
}

walker delete_account {
    has acc_id: str;

    can remove with Root entry {
        hits = [a for a in all_accounts() if jid(a) == self.acc_id];
        if not hits {
            report not_found("Conta não encontrada");
            return;
        }
        del hits[0];
        report {"status": 204};
    }
}
