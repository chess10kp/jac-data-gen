"""Reference harness: exercises every public function of iss_probcomp__bdbcontrib__73."""
from iss_probcomp__bdbcontrib__73 import Composer

c = Composer()
# Observed features feed latent clusters; clusters feed the view.
c.create_generator("age")
c.create_generator("hours")
c.create_generator("salary", parents=["age", "hours"])
c.create_generator("cluster_1", parents=["age"])
c.create_generator("cluster_2", parents=["hours", "age"])
c.create_generator("view", parents=["salary", "cluster_1"])

assert c.ancestors("view") == ["age", "cluster_1", "hours", "salary"]
assert c.ancestors("age") == []
assert c.descendants("age") == ["cluster_1", "cluster_2", "salary", "view"]
assert c.descendants("view") == []

assert c.depends_on("age", "view")
assert c.depends_on("hours", "view")
assert not c.depends_on("cluster_1", "cluster_2")
assert not c.depends_on("view", "age")
assert not c.depends_on("ghost", "age")

# Markov blanket of salary: parents age/hours, children view, co-parent cluster_1.
assert c.markov_blanket("salary") == ["age", "cluster_1", "hours", "view"]
assert c.markov_blanket("age") == ["cluster_1", "cluster_2", "hours", "salary"]
assert c.markov_blanket("view") == ["cluster_1", "salary"]
assert c.markov_blanket("ghost") == []

# Duplicate parent declarations collapse in set results.
c.create_generator("dup", parents=["age"])
c.columns["dup"].append("age")
assert c.ancestors("dup") == ["age"]

print("bdbcontrib 73 ref OK")
