"""Reference harness for rec_06_famline (deterministic fixture)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rec_06_famline import ancestor_names, born, eldest_line, generation_gap, is_blood_related, lineage_size

rosa = born(None, "Rosa", 1938)
marta = born(rosa, "Marta", 1960)
felix = born(rosa, "Felix", 1963)
nina = born(marta, "Nina", 1985)
otto = born(marta, "Otto", 1988)
pia = born(nina, "Pia", 2010)

anc = ancestor_names(pia)
print("ancestor_names(pia):", anc)
assert anc == ["Nina", "Marta", "Rosa"], anc

gaps = {"pia": generation_gap(pia), "rosa": generation_gap(rosa),
        "otto": generation_gap(otto)}
print("generation gaps:", gaps)
assert gaps == {"pia": 3, "rosa": 0, "otto": 2}, gaps

relations = {
    "pia_nina": is_blood_related(pia, nina),
    "pia_otto": is_blood_related(pia, otto),
    "pia_felix": is_blood_related(pia, felix),
}
print("blood related:", relations)
assert all(relations.values()), relations

line = eldest_line(pia)
print("eldest_line(pia):", line)
assert line == ["Rosa", "Marta", "Nina", "Pia"], line

sizes = {"rosa": lineage_size(rosa), "marta": lineage_size(marta),
         "felix": lineage_size(felix)}
print("lineage sizes:", sizes)
assert sizes == {"rosa": 6, "marta": 4, "felix": 1}, sizes

# §5.4 invariant: acyclic by construction (born only links downward).
print("rec_06_famline: all assertions passed")
