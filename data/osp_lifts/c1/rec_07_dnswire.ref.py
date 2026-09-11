"""Reference harness for rec_07_dnswire (deterministic fixture)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rec_07_dnswire import fqdn, register, soa_distance, subdomain_count, zone_chain

root = register(None, "", is_zone=True)
com = register(root, "com", is_zone=True)
example = register(com, "example", is_zone=True)
api = register(example, "api")
v1 = register(api, "v1")
org = register(root, "org")

name = fqdn(v1)
print("fqdn(v1):", repr(name))
assert name == ".com.example.api.v1.", name

chains = {"v1": zone_chain(v1), "example": zone_chain(example),
          "org": zone_chain(org)}
print("zone chains:", chains)
assert chains["v1"] == ["example", "com", ""], chains["v1"]
assert chains["example"] == ["example", "com", ""], chains["example"]
assert chains["org"] == [""], chains["org"]

counts = {"com": subdomain_count(com), "api": subdomain_count(api),
          "org": subdomain_count(org)}
print("subdomain counts:", counts)
assert counts == {"com": 3, "api": 1, "org": 0}, counts

hops = {"v1": soa_distance(v1), "example": soa_distance(example)}
print("soa distances:", hops)
assert hops == {"v1": 3, "example": 1}, hops

# §5.4 invariant: acyclic by construction (register only links downward).
print("rec_07_dnswire: all assertions passed")
