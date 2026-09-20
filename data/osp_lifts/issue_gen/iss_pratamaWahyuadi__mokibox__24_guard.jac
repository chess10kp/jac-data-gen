"""Social comment APIs - pratamaWahyuadi/mokibox#24."""

node Video {
  has vid: str;
  has owner_id: str;
  has comments_count: int = 0;
  has ready: bool = True;
}

node Comment {
  has cid: str;
  has video_id: str;
  has author_id: str;
  has content: str;
  has created_at: int;
  has parent_id: str;
}

edge OnVideo {}
edge Reply {}

walker SubtreeTally {
  has claimed: dict[str, bool] = {};
  has tally: int = 0;

  can tally with Comment entry {
    if here.cid in self.claimed {
      skip;
    }
    self.claimed[here.cid] = True;
    self.tally += 1;
    print({"visit": here.cid, "tally": self.tally});
    kids: list[Comment] = [];
    for ch in [here ->:Reply:->][?:Comment] {
      kids.append(ch);
    }
    visit :0: kids else {
      disengage;
    }
  }
}

walker SubtreeCollect {
  has claimed: dict[str, bool] = {};
  has ids: list[str] = [];

  can gather with Comment entry {
    if here.cid in self.claimed {
      skip;
    }
    self.claimed[here.cid] = True;
    self.ids.append(here.cid);
    print({"gather": here.cid});
    kids: list[Comment] = [];
    for ch in [here ->:Reply:->][?:Comment] {
      kids.append(ch);
    }
    visit :0: kids else {
      disengage;
    }
  }
}

obj CommentStore {
  has anchor: Comment;
  has videos: dict[str, Video] = {};
  has comments: dict[str, Comment] = {};
  has order: list[str] = [];
  has seq: int = 0;
}

def new_store() -> CommentStore {
  anchor = Comment(
    cid="__anchor__",
    video_id="",
    author_id="",
    content="",
    created_at=0,
    parent_id=""
  );
  root ++> anchor;
  return CommentStore(anchor=anchor);
}

def add_video(store: CommentStore, video_id: str, owner_id: str, ready: bool = True) -> None {
  v = Video(vid=video_id, owner_id=owner_id, ready=ready);
  root ++> v;
  store.videos[video_id] = v;
}

def insert_comment(
  store: CommentStore,
  video_id: str,
  author_id: str,
  content: str,
  parent_id: str | None = None
) -> dict[str, object] {
  if len(content) < 1 or len(content) > 1000 {
    raise Exception("invalid content");
  }
  if video_id not in store.videos {
    raise Exception("video not found");
  }
  vrec = store.videos[video_id];
  if not vrec.ready {
    raise Exception("video not ready");
  }
  pid = "";
  if parent_id is not None {
    pid = parent_id;
  }
  if pid != "" {
    if pid not in store.comments {
      raise Exception("parent not found");
    }
    pnd = store.comments[pid];
    if pnd.video_id != video_id {
      raise Exception("video mismatch");
    }
  }
  store.seq += 1;
  cid = "c" + str(store.seq);
  ts = store.seq;
  nd = Comment(
    cid=cid,
    video_id=video_id,
    author_id=author_id,
    content=content,
    created_at=ts,
    parent_id=pid
  );
  root ++> nd;
  vrec +>:OnVideo:+> nd;
  if pid != "" {
    pnd = store.comments[pid];
    pnd +>:Reply:+> nd;
  }
  store.comments[cid] = nd;
  store.order.append(cid);
  vrec.comments_count += 1;
  out: dict[str, object] = {};
  out["cid"] = cid;
  out["video_id"] = video_id;
  out["author_id"] = author_id;
  out["content"] = content;
  out["created_at"] = ts;
  out["parent_id"] = pid;
  return out;
}

def reply_to_comment(
  store: CommentStore,
  parent_id: str,
  author_id: str,
  content: str
) -> dict[str, object] {
  if parent_id not in store.comments {
    raise Exception("parent not found");
  }
  par = store.comments[parent_id];
  return insert_comment(store, par.video_id, author_id, content, parent_id);
}

def count_comment_subtree(store: CommentStore, comment_id: str) -> int {
  if comment_id not in store.comments {
    return 0;
  }
  nd = store.comments[comment_id];
  w = nd spawn SubtreeTally(claimed={});
  return w.tally;
}

def delete_comment(store: CommentStore, comment_id: str, requester_id: str) -> int {
  if comment_id not in store.comments {
    return 0;
  }
  root_nd = store.comments[comment_id];
  if root_nd.author_id != requester_id {
    raise Exception("forbidden");
  }
  w = root_nd spawn SubtreeCollect(claimed={});
  remove_ids: list[str] = sorted(w.ids);
  removed = 0;
  for cid in remove_ids {
    if cid not in store.comments {
      continue;
    }
    cm = store.comments[cid];
    vrec = store.videos[cm.video_id];
    vrec.comments_count -= 1;
    del store.comments[cid];
    removed += 1;
  }
  new_order: list[str] = [];
  for oid in store.order {
    if oid not in store.comments {
      continue;
    }
    new_order.append(oid);
  }
  store.order = new_order;
  return removed;
}

def list_comments(
  store: CommentStore,
  video_id: str,
  cursor: int | None = None,
  limit: int = 20
) -> list[dict[str, object]] {
  if video_id not in store.videos {
    return [];
  }
  rows: list[dict[str, object]] = [];
  for cid in store.order {
    if cid not in store.comments {
      continue;
    }
    cm = store.comments[cid];
    if cm.video_id != video_id {
      continue;
    }
    row: dict[str, object] = {};
    row["cid"] = cm.cid;
    row["video_id"] = cm.video_id;
    row["author_id"] = cm.author_id;
    row["content"] = cm.content;
    row["created_at"] = cm.created_at;
    row["parent_id"] = cm.parent_id;
    rows.append(row);
  }
  n = len(rows);
  i = 0;
  while i < n {
    j = i + 1;
    while j < n {
      if rows[j]["created_at"] > rows[i]["created_at"] {
        tmp = rows[i];
        rows[i] = rows[j];
        rows[j] = tmp;
      }
      j += 1;
    }
    i += 1;
  }
  out: list[dict[str, object]] = [];
  t = 0;
  while t < n and len(out) < limit {
    row = rows[t];
    if cursor is None or row["created_at"] < cursor {
      out.append(row);
    }
    t += 1;
  }
  return out;
}

walker BootPrint {
  has claimed: dict[str, bool] = {};

  can boot_comment with Comment entry {
    if here.cid == "__anchor__" {
      print("comment-store-ready");
      disengage;
    }
    skip;
  }
}

with entry {
  st = new_store();
  add_video(st, "v1", "owner1");
  insert_comment(st, "v1", "owner1", "seed");
  root spawn BootPrint(claimed={});
}

test "delete_subtree" {
  st = new_store();
  add_video(st, "v1", "o");
  a = insert_comment(st, "v1", "o", "a");
  aid = a["cid"] as str;
  b = insert_comment(st, "v1", "o", "b", aid);
  bid = b["cid"] as str;
  insert_comment(st, "v1", "o", "c", bid);
  n = delete_comment(st, aid, "o");
  assert n == 3;
  assert st.videos["v1"].comments_count == 0;
}

test "list_cursor" {
  st = new_store();
  add_video(st, "v1", "o");
  insert_comment(st, "v1", "o", "one");
  c2 = insert_comment(st, "v1", "u", "two");
  c3 = insert_comment(st, "v1", "o", "three");
  cid3 = c3["cid"] as str;
  ts3 = c3["created_at"] as int;
  all = list_comments(st, "v1", None, 10);
  assert (all[0]["cid"] as str) == cid3;
  page = list_comments(st, "v1", ts3, 10);
  assert len(page) == 2;
  cid2 = c2["cid"] as str;
  assert (page[0]["cid"] as str) == cid2;
}

test "reply_thread" {
  st = new_store();
  add_video(st, "v1", "o");
  root_c = insert_comment(st, "v1", "o", "root");
  root_cid = root_c["cid"] as str;
  rep = reply_to_comment(st, root_cid, "u", "reply");
  assert (rep["parent_id"] as str) == root_cid;
  assert st.videos["v1"].comments_count == 2;
}

test "count_subtree" {
  st = new_store();
  add_video(st, "v1", "o");
  a = insert_comment(st, "v1", "o", "a");
  aid = a["cid"] as str;
  insert_comment(st, "v1", "o", "b", aid);
  n = count_comment_subtree(st, aid);
  assert n == 2;
}

test "list_empty_video" {
  st = new_store();
  rows = list_comments(st, "missing", None, 10);
  assert len(rows) == 0;
}
