import uuid;
import from finance {
    User, Category, Account, HasCategory, Owns,
    create_user, create_category, get_categories, get_category, update_category, delete_category,
    create_account, get_accounts, get_account, update_account, delete_account
}

def one(w: Walker) -> dict[str, any] {
    return dict((root spawn w).reports[0]);
}

def many(w: Walker) -> list[dict[str, any]] {
    return [dict(x) for x in (root spawn w).reports[0]];
}

def new_user(tag: str) -> dict[str, any] {
    return one(create_user(nome="Ana " + tag, email="ana" + tag + "@mail.com", senha="s3nha"));
}

test "create user hashes password and rejects duplicate email" {
    tag = uuid.uuid4().hex[:8];
    u = new_user(tag);
    assert len(str(u["id"])) > 0 and u["nome"] == "Ana " + tag;
    assert u["senha_hash"] == "hashed_s3nha";
    dup = one(create_user(nome="Other", email="ana" + tag + "@mail.com", senha="x"));
    assert dup["status"] == 400 and dup["detail"] == "Email já cadastrado";
    assert len([x for x in [root -->[?:User]] if x.email == "ana" + tag + "@mail.com"]) == 1;
}

test "category belongs to its user via an edge" {
    tag = uuid.uuid4().hex[:8];
    u = new_user(tag);
    c = one(create_category(nome="Mercado", user_id=u["id"]));
    assert c["nome"] == "Mercado" and c["user_id"] == u["id"];
    owner = [x for x in [root -->[?:User]] if jid(x) == u["id"]][0];
    assert [k.nome for k in [owner ->:HasCategory:->]] == ["Mercado"];
    missing = one(create_category(nome="X", user_id="nobody"));
    assert missing["status"] == 404 and missing["detail"] == "Usuário vinculado não encontrado";
}

test "get categories filters by user and pages" {
    tag = uuid.uuid4().hex[:8];
    u1 = new_user(tag + "a");
    u2 = new_user(tag + "b");
    for n in ["c1", "c2", "c3", "c4"] {
        create_category(nome=n + tag, user_id=u1["id"]) spawn root;
    }
    one(create_category(nome="other" + tag, user_id=u2["id"]));
    mine = [c["nome"] for c in many(get_categories(user_id=u1["id"]))];
    assert mine == ["c1" + tag, "c2" + tag, "c3" + tag, "c4" + tag];
    paged = [c["nome"] for c in many(get_categories(user_id=u1["id"], limit=2, `skip=1))];
    assert paged == ["c2" + tag, "c3" + tag];
    everyone = [c["nome"] for c in many(get_categories(limit=100000))];
    assert "other" + tag in everyone and "c4" + tag in everyone;
    assert len(many(get_categories(user_id=u1["id"], limit=10, `skip=10))) == 0;
}

test "get, update and delete a category" {
    tag = uuid.uuid4().hex[:8];
    u = new_user(tag);
    c = one(create_category(nome="Lazer", user_id=u["id"]));
    assert one(get_category(cat_id=c["id"]))["nome"] == "Lazer";
    up = one(update_category(cat_id=c["id"], nome="Viagens"));
    assert up["nome"] == "Viagens" and up["user_id"] == u["id"];
    assert one(get_category(cat_id=c["id"]))["nome"] == "Viagens";
    same = one(update_category(cat_id=c["id"]));
    assert same["nome"] == "Viagens";
    assert one(delete_category(cat_id=c["id"]))["status"] == 204;
    gone = one(get_category(cat_id=c["id"]));
    assert gone["status"] == 404 and gone["detail"] == "Categoria não encontrada";
    assert one(delete_category(cat_id=c["id"]))["status"] == 404;
    assert one(update_category(cat_id="nope", nome="z"))["status"] == 404;
    assert len(many(get_categories(user_id=u["id"]))) == 0;
}

test "accounts: create, list window, get, partial update, delete" {
    tag = uuid.uuid4().hex[:8];
    u = new_user(tag);
    a = one(create_account(nome="Principal" + tag, tipo="Conta corrente", saldo_inicial=150.5, usuario_id=u["id"]));
    b = one(create_account(nome="Poupança" + tag, tipo="Poupança", saldo_inicial=0.0, usuario_id=u["id"]));
    assert a["usuario_id"] == u["id"] and a["tipo"] == "Conta corrente" and abs(a["saldo_inicial"] - 150.5) < 1e-9;
    owner = [x for x in [root -->[?:User]] if jid(x) == u["id"]][0];
    assert sorted([k.nome for k in [owner ->:Owns:->]]) == sorted(["Principal" + tag, "Poupança" + tag]);
    full = [x["id"] for x in many(get_accounts(limit=100000))];
    assert a["id"] in full and b["id"] in full;
    k = full.index(a["id"]);
    window = [x["id"] for x in many(get_accounts(limit=2, `skip=k))];
    assert window == full[k:k + 2];
    assert len(many(get_accounts())) == min(10, len(full));
    up = one(update_account(acc_id=a["id"], saldo_inicial=99.0));
    assert abs(up["saldo_inicial"] - 99.0) < 1e-9 and up["nome"] == "Principal" + tag and up["tipo"] == "Conta corrente";
    assert abs(one(get_account(acc_id=a["id"]))["saldo_inicial"] - 99.0) < 1e-9;
    assert one(delete_account(acc_id=a["id"]))["status"] == 204;
    rest = [x["id"] for x in many(get_accounts(limit=100000))];
    assert a["id"] not in rest and b["id"] in rest;
    assert one(get_account(acc_id=a["id"]))["detail"] == "Conta não encontrada";
}

test "account for unknown user is a 404" {
    r = one(create_account(nome="X", tipo="Crédito", saldo_inicial=1.0, usuario_id="ghost"));
    assert r["status"] == 404 and r["detail"] == "Usuário não encontrado";
    assert one(update_account(acc_id="ghost", nome="y"))["status"] == 404;
    assert one(delete_account(acc_id="ghost"))["status"] == 404;
}
