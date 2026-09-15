"""nginxinc/nginx-go-crossplane#142 — NGINX directive tree context by line number."""

node D {
  has name: str;
  has line: int;
  has end_line: int = -1;
  has args: list[str] = [];
}

edge child {}

walker Collect {
  has claimed: dict[str, bool] = {};
  has found: list[D] = [];
  can step with D entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    self.found.append(here);
    print here.name;
    kids: list[D] = [here ->:child:->][?:D];
    for ch in kids {
      visit ch;
    }
  }
}

walker SpanCollect {
  has target: int;
  has claimed: dict[str, bool] = {};
  has names: list[str] = [];
  can step with D entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    in_span: bool = False;
    if here.line <= self.target && here.end_line >= 0 {
      in_span = self.target <= here.end_line;
    }
    if in_span {
      self.names.append(here.name);
      print here.name;
    }
    kids: list[D] = [here ->:child:->][?:D];
    for ch in kids {
      visit ch;
    }
  }
}

def make_directive(name: str, line: int, args: list | None = None, end_line: int | None = None) -> D {
  xs: list[str] = [];
  if args is not None {
    for a in args {
      xs.append(a);
    }
  }
  el: int = -1;
  if end_line is not None {
    el = end_line;
  }
  return D(name=name, line=line, end_line=el, args=xs);
}

def link_block(parent: D, child: D) {
  parent +>:child:+> child;
}

def _has_block(nd: D) -> bool {
  kids: list[D] = [nd ->:child:->][?:D];
  return len(kids) > 0;
}

def all_directives(root_node: D) -> list[D] {
  w = root_node spawn Collect(claimed={});
  print len(w.found);
  return w.found;
}

def find_closest_directive(root_node: D, line: int) -> D | None {
  flat: list[D] = all_directives(root_node);
  possible: D | None = None;
  for d in flat {
    if d.line == line {
      return d;
    }
    if d.line < line && _has_block(d) {
      possible = d;
    }
    if d.line > line {
      return possible;
    }
  }
  return possible;
}

def context_at_line(root_node: D, line: int) -> list[str] {
  w = root_node spawn SpanCollect(target=line, claimed={});
  print len(w.names);
  return w.names;
}

test "make_directive_fields" {
  d = make_directive("listen", 5, ["80"], 5);
  assert d.name == "listen";
  assert d.line == 5;
  assert d.end_line == 5;
  assert d.args == ["80"];
}

test "all_directives_preorder" {
  http = make_directive("http", 1, end_line=100);
  server = make_directive("server", 10, end_line=80);
  loc = make_directive("location", 20, ["/api"], end_line=40);
  listen = make_directive("listen", 25, ["80"]);
  link_block(http, server);
  link_block(server, loc);
  link_block(loc, listen);
  got: list[str] = [];
  for nd in all_directives(http) {
    got.append(nd.name);
  }
  assert got == ["http", "server", "location", "listen"];
}

test "find_closest_exact_line" {
  http = make_directive("http", 1, end_line=100);
  server = make_directive("server", 10, end_line=80);
  loc = make_directive("location", 20, ["/api"], end_line=40);
  link_block(http, server);
  link_block(server, loc);
  hit = find_closest_directive(http, 20);
  assert hit is not None;
  assert hit.name == "location";
}

test "find_closest_containing_block" {
  http = make_directive("http", 1, end_line=100);
  server = make_directive("server", 10, end_line=80);
  loc = make_directive("location", 20, ["/api"], end_line=40);
  link_block(http, server);
  link_block(server, loc);
  hit = find_closest_directive(http, 15);
  assert hit is not None;
  assert hit.name == "server";
}

test "context_at_line_span" {
  http = make_directive("http", 1, end_line=100);
  server = make_directive("server", 10, end_line=80);
  loc = make_directive("location", 20, ["/api"], end_line=40);
  listen = make_directive("listen", 25, ["80"]);
  link_block(http, server);
  link_block(server, loc);
  link_block(loc, listen);
  assert context_at_line(http, 25) == ["http", "server", "location"];
}

test "context_at_line_shallow" {
  http = make_directive("http", 1, end_line=100);
  server = make_directive("server", 10, end_line=80);
  link_block(http, server);
  assert context_at_line(http, 5) == ["http"];
}
