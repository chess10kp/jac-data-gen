"""Reference harness for rec_01_orgchart (deterministic fixture)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rec_01_orgchart import find_by_title, hire, management_chain, org_depth, team_size

# Fixture (deterministic creation order): CEO -> two VPs -> ICs.
ceo = hire(None, "Morgan", "CEO")
vp_eng = hire(ceo, "Lee", "VP Eng")
vp_sales = hire(ceo, "Pat", "VP Sales")
dev1 = hire(vp_eng, "Sasha", "Dev")
dev2 = hire(vp_eng, "Jamie", "Dev")
acct = hire(vp_sales, "Casey", "Acct")

chain = management_chain(dev2)
print("management_chain(dev2):", chain)
assert chain == ["VP Eng", "CEO"], chain

chain_ceo = management_chain(ceo)
print("management_chain(ceo):", chain_ceo)
assert chain_ceo == [], chain_ceo

sizes = {"ceo": team_size(ceo), "vp_eng": team_size(vp_eng),
         "dev1": team_size(dev1), "acct": team_size(acct)}
print("team sizes:", sizes)
assert sizes == {"ceo": 6, "vp_eng": 3, "dev1": 1, "acct": 1}, sizes

depths = {"ceo": org_depth(ceo), "vp_sales": org_depth(vp_sales),
          "dev2": org_depth(dev2)}
print("org depths:", depths)
assert depths == {"ceo": 3, "vp_sales": 2, "dev2": 1}, depths

devs = find_by_title(ceo, "Dev")
print("find_by_title(ceo, 'Dev'):", devs)
assert devs == ["Dev", "Dev"], devs

none_found = find_by_title(dev1, "CEO")
print("find_by_title(dev1, 'CEO'):", none_found)
assert none_found == [], none_found

# §5.4 invariant: tree is acyclic by construction (hire only links downward).
print("rec_01_orgchart: all assertions passed")
