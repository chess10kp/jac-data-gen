"""rust-lang/rust#69684 — recursive directory listing lifted to OSP graph walk."""

node Dir {
  has cid: str;
  has path: str;
}

node File {
  has cid: str;
  has path: str;
}

edge Child {}

def read_dir(root_id: str, store: dict[str, object]) -> list[str] {
  if root_id not in store {
    return [];
  }
  parent = store[root_id];
  kids: list[str] = [];
  for ch in [parent ->:Child:->][?:Dir] {
    kids.append(ch.path);
  }
  for ch in [parent ->:Child:->][?:File] {
    kids.append(ch.path);
  }
  return sorted(kids);
}

walker ReadDirAllW {
  has claimed: dict[str, bool] = {};
  has found: list[str] = [];
  has root_id: str = "";

  can walk_dir with Dir entry {
    if here.cid in self.claimed {
      skip;
    }
    self.claimed[here.cid] = True;
    if here.cid != self.root_id {
      self.found.append(here.path);
    }
    nbrs: list[object] = [];
    for ch in [here ->:Child:->][?:Dir] {
      nbrs.append(ch);
    }
    for ch in [here ->:Child:->][?:File] {
      nbrs.append(ch);
    }
    if len(nbrs) > 0 {
      visit :0: nbrs;
    } else {
      disengage;
    }
  }

  can walk_file with File entry {
    if here.cid in self.claimed {
      skip;
    }
    self.claimed[here.cid] = True;
    self.found.append(here.path);
    disengage;
  }
}

def read_dir_all(root_id: str, store: dict[str, object]) -> list[str] {
  if root_id not in store {
    return [];
  }
  root_node = store[root_id];
  w = root_node spawn ReadDirAllW(root_id=root_id);
  print(w.found);
  return sorted(w.found);
}

def make_sample_tree -> dict[str, object] {
  store: dict[str, object] = {};
  d0 = Dir(cid="d0", path="/proj");
  d1 = Dir(cid="d1", path="/proj/src");
  f0 = File(cid="f0", path="/proj/README.md");
  f1 = File(cid="f1", path="/proj/src/main.rs");
  root ++> d0;
  d0 +>:Child:+> d1;
  d0 +>:Child:+> f0;
  d1 +>:Child:+> f1;
  store["d0"] = d0;
  store["d1"] = d1;
  store["f0"] = f0;
  store["f1"] = f1;
  return store;
}

with entry {
  st: dict[str, object] = make_sample_tree();
  w = root spawn ReadDirAllW(root_id="d0");
  print(w.found);
  print(read_dir("d0", st));
}

test "read_dir_root_children" {
  st: dict[str, object] = make_sample_tree();
  got = read_dir("d0", st);
  assert (got == ["/proj/README.md", "/proj/src"]);;
}

test "read_dir_all_from_root" {
  st: dict[str, object] = make_sample_tree();
  got = read_dir_all("d0", st);
  assert (got == ["/proj/README.md", "/proj/src", "/proj/src/main.rs"]);;
}

test "read_dir_leaf_dir" {
  st: dict[str, object] = make_sample_tree();
  got = read_dir("d1", st);
  assert (got == ["/proj/src/main.rs"]);;
}

test "read_dir_unknown_id" {
  st: dict[str, object] = make_sample_tree();
  got = read_dir("missing", st);
  assert (got == []);;
}

test "read_dir_all_unknown_id" {
  st: dict[str, object] = make_sample_tree();
  got = read_dir_all("missing", st);
  assert (got == []);;
}

test "read_dir_all_excludes_root_path" {
  st: dict[str, object] = make_sample_tree();
  got = read_dir_all("d0", st);
  assert ("/proj" not in got);;
}
