"""ttttmr/pi-context#26 DCP-style ranged context compaction."""

node Msg {
  has mid: str;
  has body: str;
}

edge Next {}

walker CollectOrder {
  has claimed: dict[str, bool] = {};
  has order: list[str] = [];
  can walk with Msg entry {
    if here.mid in self.claimed {
      skip;
    }
    self.claimed[here.mid] = True;
    self.order.append(here.mid);
    print(here.mid);
    kids: list[Msg] = [];
    for ch in [here ->:Next:->][?:Msg] {
      kids.append(ch);
    }
    if kids {
      visit :0: kids;
    }
  }
}

def index_ids(ids: list[str]) -> dict[str, int] {
  out: dict[str, int] = {};
  i = 0;
  while i < len(ids) {
    out[ids[i]] = i;
    i += 1;
  }
  return out;
}

def sort_ranges_by_start(ids: list[str], ranges: list[dict]) -> list[dict] {
  idx: dict[str, int] = index_ids(ids);
  n = len(ranges);
  order: list[int] = [];
  i = 0;
  while i < n {
    order.append(i);
    i += 1;
  }
  i = 0;
  while i < n {
    best = i;
    j = i + 1;
    while j < n {
      ri = order[i];
      rj = order[j];
      si = idx[ranges[ri]["start"] as str];
      sj = idx[ranges[rj]["start"] as str];
      if sj < si {
        best = j;
      }
      j += 1;
    }
    if best != i {
      tmp = order[i];
      order[i] = order[best];
      order[best] = tmp;
    }
    i += 1;
  }
  out: list[dict] = [];
  k = 0;
  while k < n {
    out.append(ranges[order[k]]);
    k += 1;
  }
  return out;
}

def make_summary_id(start_id: str, end_id: str) -> str {
  return "summary:" + start_id + ":" + end_id;
}

def validate_compaction_ranges(ids: list[str], ranges: list[dict], frontier_protect: int = 2) -> bool {
  if frontier_protect < 0 {
    return False;
  }
  if len(ranges) == 0 {
    return True;
  }
  idx: dict[str, int] = index_ids(ids);
  frontier_start = len(ids) - frontier_protect;
  sorted_rs: list[dict] = sort_ranges_by_start(ids, ranges);
  prev_end = -1;
  ri = 0;
  while ri < len(sorted_rs) {
    r = sorted_rs[ri];
    start_id = r["start"] as str;
    end_id = r["end"] as str;
    if start_id not in idx {
      return False;
    }
    if end_id not in idx {
      return False;
    }
    si = idx[start_id];
    ei = idx[end_id];
    if si > ei {
      return False;
    }
    if ei >= frontier_start {
      return False;
    }
    if si <= prev_end {
      return False;
    }
    prev_end = ei;
    ri += 1;
  }
  return True;
}

def context_compact_range(ids: list[str], ranges: list[dict], frontier_protect: int = 2) -> list[str] {
  if not validate_compaction_ranges(ids, ranges, frontier_protect) {
    return ids;
  }
  if len(ranges) == 0 {
    return ids;
  }
  idx: dict[str, int] = index_ids(ids);
  sorted_rs: list[dict] = sort_ranges_by_start(ids, ranges);
  out: list[str] = [];
  pos = 0;
  ri = 0;
  while pos < len(ids) {
    applied = False;
    if ri < len(sorted_rs) {
      r = sorted_rs[ri];
      start_id = r["start"] as str;
      end_id = r["end"] as str;
      si = idx[start_id];
      ei = idx[end_id];
      if pos == si {
        out.append(make_summary_id(start_id, end_id));
        pos = ei + 1;
        ri += 1;
        applied = True;
      }
    }
    if not applied {
      out.append(ids[pos]);
      pos += 1;
    }
  }
  return out;
}

def build_message_chain(mids: list[str]) -> Msg {
  nodes: list[Msg] = [];
  i = 0;
  while i < len(mids) {
    nd = Msg(mid=mids[i], body=mids[i]);
    root ++> nd;
    nodes.append(nd);
    i += 1;
  }
  j = 0;
  while j < len(nodes) - 1 {
    nodes[j] +>:Next:+> nodes[j + 1];
    j += 1;
  }
  return nodes[0];
}

def build_diamond_chain() -> Msg {
  a = Msg(mid="A", body="A");
  b = Msg(mid="B", body="B");
  c = Msg(mid="C", body="C");
  d = Msg(mid="D", body="D");
  root ++> a;
  a +>:Next:+> b;
  a +>:Next:+> c;
  b +>:Next:+> d;
  c +>:Next:+> d;
  return a;
}

def collect_message_order(head: Msg) -> list[str] {
  w = head spawn CollectOrder(claimed={});
  return w.order;
}

with entry {
  mids: list[str] = ["A", "B", "C", "D", "E", "F"];
  head = build_message_chain(mids);
  w = head spawn CollectOrder(claimed={});
  rs: list[dict] = [];
  r0: dict = {};
  r0["start"] = "C";
  r0["end"] = "D";
  r0["summary"] = "cd summary";
  rs.append(r0);
  print(context_compact_range(w.order, rs, 2));
}
