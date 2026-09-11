"""Reference harness for rec_08_pkgdeps (deterministic fixture)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rec_08_pkgdeps import dep_tree_size, install_path, register, resolve, versions_under

reg = {}
root = register(reg, None, "app", "1.0.0")
left_pad = register(reg, root, "left-pad", "1.3.0")
lodash = register(reg, root, "lodash", "4.17.21")
ms = register(reg, left_pad, "ms", "2.1.3")
lodash_nested = register(reg, left_pad, "lodash@3", "3.10.1")

print("resolve(reg, 'ms'):", resolve(reg, "ms").version)
assert resolve(reg, "ms").version == "2.1.3"

try:
    resolve(reg, "ghost")
    missing_raised = False
except KeyError:
    missing_raised = True
print("resolve(reg, 'ghost') raises KeyError:", missing_raised)
assert missing_raised

try:
    register(reg, root, "app", "9.9.9")
    dup_raised = False
except ValueError:
    dup_raised = True
print("duplicate register raises ValueError:", dup_raised)
assert dup_raised

print("install_path(ms):", install_path(ms))
assert install_path(ms) == "app / left-pad / ms", install_path(ms)

sizes = {"app": dep_tree_size(root), "left-pad": dep_tree_size(left_pad),
         "ms": dep_tree_size(ms)}
print("dep tree sizes:", sizes)
assert sizes == {"app": 5, "left-pad": 3, "ms": 1}, sizes

lv = versions_under(root, "lodash")
print("versions_under(root, 'lodash'):", lv)
assert lv == ["3.10.1", "4.17.21"], lv

# §5.4 invariant: acyclic by construction (register only links downward).
print("rec_08_pkgdeps: all assertions passed")
