"""Reference harness for rec_05_taxonomy (deterministic fixture)."""
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from rec_05_taxonomy import breadcrumb, classify, contains, rank_spread_list, species_count

life = classify(None, "Life", "root")
animalia = classify(life, "Animalia", "kingdom")
chordata = classify(animalia, "Chordata", "phylum")
mammalia = classify(chordata, "Mammalia", "class")
canis = classify(mammalia, "Canis", "genus")
lupus = classify(canis, "lupus", "species")
familiaris = classify(canis, "familiaris", "species")
plantae = classify(life, "Plantae", "kingdom")

crumb = breadcrumb(familiaris)
print("breadcrumb(familiaris):", crumb)
assert crumb == [
    "root:Life",
    "kingdom:Animalia",
    "phylum:Chordata",
    "class:Mammalia",
    "genus:Canis",
    "species:familiaris",
], crumb

counts = {"life": species_count(life), "canis": species_count(canis),
          "plantae": species_count(plantae)}
print("species counts:", counts)
assert counts == {"life": 2, "canis": 2, "plantae": 0}, counts

checks = {"hit": contains(life, "lupus"), "miss": contains(life, "fungi"),
          "self": contains(plantae, "Plantae")}
print("contains:", checks)
assert checks == {"hit": True, "miss": False, "self": True}, checks

spread = rank_spread_list(animalia)
print("rank_spread_list(animalia):", spread)
assert spread == ["class", "genus", "kingdom", "phylum", "species"], spread

# §5.4 invariant: acyclic by construction (classify only links downward).
print("rec_05_taxonomy: all assertions passed")
