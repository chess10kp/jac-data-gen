"""Reference harness for rec_38_aclinherit (access control). Exit 0."""
import sys

sys.path.insert(0, "/home/jac/repos/jac_llm_data/data/osp_lifts/combo")
from rec_38_aclinherit import AclSystem


def build():
    a = AclSystem()
    a.add_role("root")
    a.add_role("admin", parent="root")
    a.add_role("dev", parent="admin")
    a.add_role("intern", parent="admin")
    a.add_role("guest", parent="root")
    a.grant("root", "login")
    a.grant("admin", "deploy")
    a.grant("dev", "commit")
    return a


def test_structure_and_chain_order():
    a = build()
    assert sorted(a.roles) == ["admin", "dev", "guest", "intern", "root"]
    # observable ordering: self -> ... -> root
    assert a.chain("dev") == ["dev", "admin", "root"]
    assert a.chain("root") == ["root"]
    assert a.direct_grants("dev") == ["commit"]
    try:
        a.add_role("root")
        raise AssertionError("expected duplicate error")
    except ValueError:
        pass


def test_effective_inheritance():
    a = build()
    assert a.effective("dev") == ["commit", "deploy", "login"]
    assert a.effective("guest") == ["login"]
    assert a.cache_coherent()


def test_revoke_cascade():
    a = build()
    affected = a.revoke("deploy")   # admin holds; dev+intern inherit
    assert affected == ["admin", "dev", "intern"]
    assert a.effective("dev") == ["commit", "login"]
    assert a.effective("intern") == ["login"]
    assert a.direct_grants("admin") == []
    assert a.cache_coherent()
    # revoking unknown perm is a no-op
    assert a.revoke("nope") == []


def test_revoke_scoped_to_holder_subtree():
    a = build()
    a.grant("guest", "read")
    affected = a.revoke("login")    # root holds; everyone inherits
    assert affected == ["admin", "dev", "guest", "intern", "root"]
    assert a.effective("dev") == ["commit", "deploy"]
    assert a.effective("guest") == ["read"]
    assert a.cache_coherent()


test_structure_and_chain_order()
test_effective_inheritance()
test_revoke_cascade()
test_revoke_scoped_to_holder_subtree()
print("rec_38 ref OK")
sys.exit(0)
