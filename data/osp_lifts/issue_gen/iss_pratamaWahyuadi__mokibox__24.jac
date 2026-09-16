# pratamaWahyuadi/mokibox#24 — comments, replies, cascade delete via OSP walkers

node Video { has ready: bool = True; }
node Comment {
  has cid: str;
  has author: str;
  has content: str;
  has created_at: int;
}
edge reply_to {}
edge posted_on {}
edge owns {}

def _check_content(content: str) -> bool {
    return len(content) >= 1 and len(content) <= 1000;
}

walker InsertComment {
  has video_id: str;
  has cid: str;
  has author: str;
  has content: str;
  has ts: int;
  has ok: bool = False;
  can go with root entry {
    v: Video | None = None;
    for vv in [root ->:owns:->][?:Video] {
      if vv.cid == self.video_id { v = vv; }
    }
    if v is None or not v.ready or not _check_content(self.content) {
      disengage;
    }
    c = Comment(cid=self.cid, author=self.author, content=self.content, created_at=self.ts);
    here ++> c;
    c +>:posted_on:+> v;
    self.ok = True;
    print("inserted " + self.cid);
    visit [v];
  }
  can notify with Video entry {
    print("notify video owner type=comment");
    disengage;
  }
}

walker ReplyComment {
  has parent_id: str;
  has cid: str;
  has author: str;
  has content: str;
  has ts: int;
  has ok: bool = False;
  claimed: dict[str, bool] = {};
  can go with root entry {
    par: Comment | None = None;
    for c in [root ->:owns:->][?:Comment] {
      if c.cid == self.parent_id { par = c; }
    }
    if par is None or not _check_content(self.content) { disengage; }
    c = Comment(cid=self.cid, author=self.author, content=self.content, created_at=self.ts);
    here ++> c;
    par +>:reply_to:+> c;
    self.ok = True;
    print("reply " + self.cid);
    visit [par] else { disengage; }
  }
  can walk_up with Comment entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    print("notify parent author " + here.author);
    visit [here ->:reply_to:->][?:Comment] else { disengage; }
  }
}

walker CountSubtree {
  has target: str;
  has count: int = 0;
  claimed: dict[str, bool] = {};
  can go with root entry {
    found: list[Comment] = [];
    for c in [root ->:owns:->][?:Comment] {
      if c.cid == self.target { found.append(c); }
    }
    if len(found) == 0 { disengage; }
    visit [found[0]];
  }
  can collect with Comment entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    self.count = self.count + 1;
    visit [here ->:reply_to:->][?:Comment];
  }
}

walker ListComments {
  has video_id: str;
  has cursor: int = 0;
  has out: list[tuple[int, str]] = [];
  can go with root entry {
    for c in [root <-:posted_on:-][?:Comment] {
      if self.cursor > 0 and c.created_at >= self.cursor { skip; }
      self.out.append((c.created_at, c.cid));
    }
    self.out = sorted(self.out);
    for item in self.out { print(item[1]); }
    disengage;
  }
}

walker DeleteComment {
  has target: str;
  has ok: bool = False;
  claimed: dict[str, bool] = {};
  can go with root entry {
    found: list[Comment] = [];
    for c in [root ->:owns:->][?:Comment] {
      if c.cid == self.target { found.append(c); }
    }
    if len(found) == 0 { disengage; }
    self.ok = True;
    print("deleting subtree of " + self.target);
    visit [found[0]];
  }
  can sweep with Comment entry {
    if here.cid in self.claimed { skip; }
    self.claimed[here.cid] = True;
    print("delete " + here.cid);
    visit [here ->:reply_to:->][?:Comment];
  }
}

def insert_comment(root_node: root, video_id: str, cid: str, author: str, content: str, ts: int) -> bool {
    w = root_node spawn InsertComment(video_id=video_id, cid=cid, author=author, content=content, ts=ts);
    return w.ok;
}

def reply_comment(root_node: root, parent_id: str, cid: str, author: str, content: str, ts: int) -> bool {
    w = root_node spawn ReplyComment(parent_id=parent_id, cid=cid, author=author, content=content, ts=ts);
    return w.ok;
}

def count_subtree(root_node: root, target: str) -> int {
    w = root_node spawn CountSubtree(target=target);
    return w.count;
}

def list_comments(root_node: root, video_id: str, cursor: int = 0) -> list[tuple[int, str]] {
    w = root_node spawn ListComments(video_id=video_id, cursor=cursor);
    return w.out;
}

def delete_comment(root_node: root, target: str) -> bool {
    w = root_node spawn DeleteComment(target=target);
    return w.ok;
}
