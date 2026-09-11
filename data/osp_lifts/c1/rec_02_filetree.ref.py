"""Reference harness for rec_02_filetree (deterministic fixture)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rec_02_filetree import create, deepest_dir, dir_size, files_under, path_of

root = create(None, "home", True)
docs = create(root, "docs", True)
src = create(root, "src", True)
readme = create(docs, "readme.md", False, 1200)
notes = create(docs, "notes.txt", False, 300)
main = create(src, "main.py", False, 800)
util = create(src, "util.py", False, 450)

print("path_of(main):", path_of(main))
assert path_of(main) == "/home/src/main.py", path_of(main)

print("path_of(root):", path_of(root))
assert path_of(root) == "/home", path_of(root)

sizes = {"root": dir_size(root), "docs": dir_size(docs), "main": dir_size(main)}
print("sizes:", sizes)
assert sizes == {"root": 2750, "docs": 1500, "main": 800}, sizes

md = files_under(root, ".md")
txt = files_under(docs, ".py")
print("files_under(root, '.md'):", md)
print("files_under(docs, '.py'):", txt)
assert md == ["readme.md"], md
assert txt == [], txt

depths = {"root": deepest_dir(root), "src": deepest_dir(src), "readme": deepest_dir(readme)}
print("deepest_dir:", depths)
assert depths == {"root": 2, "src": 1, "readme": 0}, depths

# §5.4 invariant: acyclic by construction (create only links downward).
print("rec_02_filetree: all assertions passed")
