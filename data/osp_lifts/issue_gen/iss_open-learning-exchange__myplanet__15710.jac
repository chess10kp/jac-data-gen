"""Cycle-safe news thread ID collection — recursive CTE lift.

open-learning-exchange/myplanet#15710
"""

node News {
  has nid: str;
  has title: str = "";
}

edge ReplyTo {}

obj NewsDao {
  has nodes: dict[str, News] = {};

  def add_news(nid: str, title: str = "") -> News {
    nd = News(nid=nid, title=title);
    self.nodes[nid] = nd;
    root ++> nd;
    return nd;
  }

  def link_reply(parent_id: str, child_id: str) -> bool {
    if parent_id not in self.nodes {
      return False;
    }
    if child_id not in self.nodes {
      return False;
    }
    parent = self.nodes[parent_id];
    child = self.nodes[child_id];
    parent +>:ReplyTo:+> child;
    return True;
  }

  def collect_news_and_replies(news_id: str) -> list[str] {
    if news_id not in self.nodes {
      return [];
    }
    start = self.nodes[news_id];
    w = start spawn ThreadCollector(claimed={}, collected=[]);
    return w.collected;
  }
}

walker ThreadCollector {
  has claimed: dict[str, bool] = {};
  has collected: list[str] = [];

  can walk with News entry {
    if here.nid in self.claimed {
      skip;
    }
    self.claimed[here.nid] = True;
    self.collected.append(here.nid);
    print("collect", here.nid);
    kids: list[News] = [];
    for ch in [here ->:ReplyTo:->][?:News] {
      kids.append(ch);
    }
    if len(kids) > 0 {
      visit :0: kids;
    }
  }
}

walker Demo {
  can run with News entry {
    root spawn ThreadCollector(claimed={}, collected=[]);
    print("demo_ready");
    disengage;
  }
}
