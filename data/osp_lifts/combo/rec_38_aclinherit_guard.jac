"""Guard suite for rec_38_aclinherit."""
import from rec_38_aclinherit { AclSystem }

def fresh() -> AclSystem {
    a = AclSystem();
    a.add_role("root");
    a.add_role("admin", parent="root");
    a.add_role("dev", parent="admin");
    a.add_role("intern", parent="admin");
    a.add_role("guest", parent="root");
    a.grant("root", "login");
    a.grant("admin", "deploy");
    a.grant("dev", "commit");
    return a;
}

test "chain order is observable" {
    a = fresh();
    assert a.chain("dev") == ["dev", "admin", "root"];
    assert a.chain("root") == ["root"];
    assert a.direct_grants("dev") == ["commit"];
    threw = False;
    try {
        a.add_role("root");
    } except ValueError as ex {
        threw = True;
    }
    assert threw;
}

test "effective sets inherit down the hierarchy" {
    a = fresh();
    assert a.effective("dev") == ["commit", "deploy", "login"];
    assert a.effective("guest") == ["login"];
    assert a.cache_coherent();
}

test "revoke cascades to inheriting roles" {
    a = fresh();
    affected = a.revoke("deploy");
    assert affected == ["admin", "dev", "intern"];
    assert a.effective("dev") == ["commit", "login"];
    assert a.effective("intern") == ["login"];
    assert a.direct_grants("admin") == [];
    assert a.cache_coherent();
    assert a.revoke("nope") == [];
}

test "revoke scoped to holder subtree only" {
    a = fresh();
    a.grant("guest", "read");
    affected = a.revoke("login");  # root holds it; whole tree affected
    assert len(affected) == len(set(affected));
    assert affected == ["admin", "dev", "guest", "intern", "root"];
    assert a.effective("dev") == ["commit", "deploy"];
    assert a.effective("guest") == ["read"];
    assert a.cache_coherent();
}

test "grant then revoke round-trip restores coherence" {
    a = fresh();
    a.grant("intern", "commit");
    assert a.effective("intern") == ["commit", "deploy", "login"];
    a.revoke("commit");  # dev and intern both hold it
    assert a.effective("dev") == ["deploy", "login"];
    assert a.effective("intern") == ["deploy", "login"];
    assert a.cache_coherent();
}
