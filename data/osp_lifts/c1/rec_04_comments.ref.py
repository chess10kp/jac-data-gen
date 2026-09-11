"""Reference harness for rec_04_comments (deterministic fixture)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rec_04_comments import deepest_reply, op_author, post, reply_count, thread_path

op = post(None, "ana", "launch day!")
r1 = post(op, "bo", "congrats")
r2 = post(op, "cy", "how does auth work?")
r11 = post(r1, "ana", "thanks!")
r21 = post(r2, "dee", "JWTs")
r211 = post(r21, "bo", "any rotation?")

path = thread_path(r211)
print("thread_path(r211):", path)
assert path == ["ana", "cy", "dee", "bo"], path

print("thread_path(op):", thread_path(op))
assert thread_path(op) == ["ana"], thread_path(op)

counts = {"op": reply_count(op), "r2": reply_count(r2), "r11": reply_count(r11)}
print("reply counts:", counts)
assert counts == {"op": 5, "r2": 2, "r11": 0}, counts

print("op_author(r211):", op_author(r211))
assert op_author(r211) == "ana", op_author(r211)

depths = {"op": deepest_reply(op), "r1": deepest_reply(r1), "r21": deepest_reply(r21)}
print("deepest_reply:", depths)
assert depths == {"op": 4, "r1": 2, "r21": 2}, depths

# §5.4 invariant: acyclic by construction (post only links downward).
print("rec_04_comments: all assertions passed")
