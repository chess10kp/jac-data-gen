"""Reference harness: exercises every public function of iss_pratapram__dale__24."""
from iss_pratapram__dale__24 import resolve_entities

records = [
    {"id": 1, "email": "a@x.io", "phone": "555-0001"},
    {"id": 2, "email": "a@x.io", "phone": ""},
    {"id": 3, "email": "b@x.io", "phone": "555-0002"},
    {"id": 4, "email": "", "phone": "555-0002"},
    {"id": 5, "email": "c@x.io", "phone": "555-0003"},
]
# Transitive chain: 1~2 share email, 3~4 share phone, and 2~3? no -- but
# 1..2 form one entity, 3..4 another, 5 alone.
label = resolve_entities(records, ["email", "phone"])
assert label[1] == label[2] == min([1, 2])
assert label[3] == label[4] == 3
assert label[5] == 5

# Merge-through: linking 2 and 3 transitively joins all of 1..4.
linked = records + [{"id": 2, "email": "bridge@x.io", "phone": ""}, {"id": 3, "email": "bridge@x.io", "phone": "555-0002"}]
label2 = resolve_entities(linked, ["email", "phone"])
ents = {label2[r["id"]] for r in linked}
assert ents == {1, 5}

# Blank values never merge: two blank-email records stay apart.
blanks = [
    {"id": 7, "email": "", "phone": "p1"},
    {"id": 8, "email": "", "phone": "p1"},  # same phone DOES merge
    {"id": 9, "email": "", "phone": "p2"},
]
label3 = resolve_entities(blanks, ["email", "phone"])
assert label3[7] == label3[8]
assert label3[9] == 9

# Single link field only.
label4 = resolve_entities(records, ["email"])
assert label4[1] == label4[2]
assert label4[3] != label4[4]

print("iss_pratapram__dale__24 ref OK")
