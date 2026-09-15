"""GraphQL @recursive(maxDepth) nested field resolution — graphql/graphql-spec#237."""

node Person {
  has pid: str;
  has name: str;
}

edge Parent {}
edge Boss {}

def make_empty_graph() -> Person {
  return Person(pid="__graph__", name="schema");
}

def add_person(graph_root: Person, pid: str, name: str) -> Person {
  p = Person(pid=pid, name=name);
  graph_root ++> p;
  return p;
}

def link_parent(child: Person, parent: Person) {
  child +>:Parent:+> parent;
}

def link_boss(employee: Person, boss: Person) {
  employee +>:Boss:+> boss;
}

def find_person(graph_root: Person, pid: str) -> Person | None {
  if graph_root.pid == pid {
    return graph_root;
  }
  for n in [graph_root -->][?:Person] {
    if n.pid == pid {
      return n;
    }
  }
  return None;
}

walker RecursiveChain {
  has relation: str;
  has max_depth: int;
  has depth: int = 0;
  has claimed: dict[str, bool] = {};
  has found: list[str] = [];

  can follow with Person entry {
    if here.pid in self.claimed {
      skip;
    }
    self.claimed[here.pid] = True;
    if self.depth > 0 {
      self.found.append(here.pid);
    }
    print("recursive", self.relation, here.pid, self.depth);
    if self.depth < self.max_depth {
      self.depth += 1;
      next_hops: list[Person] = [];
      if self.relation == "parents" {
        for tgt in [here ->:Parent:->][?:Person] {
          next_hops.append(tgt);
        }
      }
      if self.relation == "boss" {
        for tgt in [here ->:Boss:->][?:Person] {
          next_hops.append(tgt);
        }
      }
      if len(next_hops) > 0 {
        visit :0: next_hops;
      }
    }
  }
}

def resolve_recursive(
  graph_root: Person,
  start_id: str,
  relation: str,
  max_depth: int
) -> list[str] {
  start = find_person(graph_root, start_id);
  if start is None {
    return [];
  }
  w = start spawn RecursiveChain(
    relation=relation,
    max_depth=max_depth,
    depth=0,
    claimed={},
    found=[]
  );
  return w.found;
}

def resolve_selection(
  graph_root: Person,
  root_id: str,
  relations: list[str],
  max_depths: dict[str, int],
  default_max_depth: int
) -> dict[str, list[str]] {
  out: dict[str, list[str]] = {};
  for rel in relations {
    md = default_max_depth;
    if rel in max_depths {
      md = max_depths[rel] as int;
    }
    out[rel] = resolve_recursive(graph_root, root_id, rel, md);
  }
  return out;
}

def build_person_graph() -> Person {
  g = make_empty_graph();
  alice = add_person(g, "1", "Alice");
  bob = add_person(g, "2", "Bob");
  carol = add_person(g, "3", "Carol");
  dave = add_person(g, "4", "Dave");
  eve = add_person(g, "5", "Eve");
  link_parent(alice, bob);
  link_parent(alice, carol);
  link_parent(bob, dave);
  link_parent(carol, dave);
  link_boss(bob, carol);
  link_boss(carol, dave);
  link_boss(eve, bob);
  return g;
}

test "unknown_start_returns_empty" {
  g = build_person_graph();
  got = resolve_recursive(g, "missing", "parents", 3);
  assert len(got) == 0;;
}

test "parents_depth2_sorted" {
  g = build_person_graph();
  got = resolve_recursive(g, "1", "parents", 2);
  assert sorted(got) == ["2", "3", "4"];;
}

test "diamond_shared_ancestor_once" {
  g = build_person_graph();
  got = resolve_recursive(g, "1", "parents", 3);
  assert sorted(got) == ["2", "3", "4"];;
  assert got.count("4") == 1;;
}

test "adversarial_revisit_before_deep" {
  g = build_person_graph();
  got = resolve_recursive(g, "1", "parents", 3);
  assert sorted(got) == ["2", "3", "4"];;
  assert got.count("3") == 1;;
  assert got.count("4") == 1;;
}

test "boss_chain_from_eve" {
  g = build_person_graph();
  got = resolve_recursive(g, "5", "boss", 3);
  assert sorted(got) == ["2", "3", "4"];;
}

test "resolve_selection_parents_and_boss" {
  g = build_person_graph();
  rels: list[str] = ["parents", "boss"];
  depths: dict[str, int] = {"parents": 2};
  got = resolve_selection(g, "1", rels, depths, 1);
  assert sorted(got["parents"]) == ["2", "3", "4"];;
  assert len(got["boss"]) == 0;;
}
