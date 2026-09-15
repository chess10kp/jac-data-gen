"""orion-ecs/keen-eye#1310 — layout dirty consumption, cursor clamp, z-index cap."""

glob OVERLAY_Z_THRESHOLD = 1000;
glob MAX_SAFE_Z = 999;

node UINode {
    has cid: str;
    has layout_dirty: bool = False;
    has w: int = 0;
    has h: int = 0;
}

node TextField {
    has cid: str;
    has content: str = "";
    has cursor_pos: int = 0;
}

node Window {
    has cid: str;
    has has z_order: int = 0;
    has local_z: int = 0;
}

edge Child {}

walker LayoutSweep {
    has claimed: dict[str, bool] = {};
    has dirty_only: bool = False;
    has relayout_count: int = 0;
    has touched: list[str] = [];

    can step with UINode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        do_measure: bool = True;
        if self.dirty_only and not here.layout_dirty {
            do_measure = False;
        }
        if do_measure {
            self.relayout_count += 1;
            here.w = 10 + len(here.cid);
            here.h = 5;
            here.layout_dirty = False;
            self.touched.append(here.cid);
        }
        kids: list[UINode] = [];
        for ch in [here ->:Child:->][?:UINode] {
            kids.append(ch);
        }
        if kids { visit :0: kids; } else { disengage; }
        print(["layout", here.cid, self.relayout_count]);
    }
}

walker Finder {
    has target: str;
    has claimed: dict[str, bool] = {};
    has hit_ui: UINode | None = None;
    has hit_text: TextField | None = None;
    has hit_win: Window | None = None;

    can scan_entry with entry {
        kids: list[object] = [];
        for ch in [here ->] {
            kids.append(ch);
        }
        if kids { visit :0: kids; } else { disengage; }
        print(["find_entry"]);
    }

    can scan_ui with UINode entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid == self.target { self.hit_ui = here; }
        kids: list[object] = [];
        for ch in [here ->:Child:->] {
            kids.append(ch);
        }
        if kids { visit :0: kids; } else { disengage; }
        print(["find_ui", here.cid]);
    }

    can scan_text with TextField entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid == self.target { self.hit_text = here; }
        kids: list[object] = [];
        for ch in [here ->] {
            kids.append(ch);
        }
        if kids { visit :0: kids; } else { disengage; }
        print(["find_text", here.cid]);
    }

    can scan_win with Window entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.cid == self.target { self.hit_win = here; }
        kids: list[object] = [];
        for ch in [here ->] {
            kids.append(ch);
        }
        if kids { visit :0: kids; } else { disengage; }
        print(["find_win", here.cid]);
    }
}

def set_layout_dirty(element_id: str) -> bool {
    fw = root spawn Finder(target=element_id, claimed={});
    if fw.hit_ui is None { return False; }
    fw.hit_ui.layout_dirty = True;
    return True;
}

def relayout_subtree(root_id: str, dirty_only: bool = False) -> list[str] {
    fw = root spawn Finder(target=root_id, claimed={});
    if fw.hit_ui is None { return []; }
    sw = fw.hit_ui spawn LayoutSweep(
        claimed={}, dirty_only=dirty_only, relayout_count=0, touched=[]
    );
    out: list[str] = [];
    for cid in sw.touched { out.append(cid); }
    return sorted(out);
}

def insert_text_clamped(field_id: str, ch: str) -> str | None {
    fw = root spawn Finder(target=field_id, claimed={});
    if fw.hit_text is None { return None; }
    tf = fw.hit_text;
    pos: int = tf.cursor_pos;
    if pos < 0 { pos = 0; }
    clen: int = len(tf.content);
    if pos > clen { pos = clen; }
    new_content: str = "";
    i: int = 0;
    while i < pos {
        new_content += tf.content[i];
        i += 1;
    }
    new_content += ch;
    while i < clen {
        new_content += tf.content[i];
        i += 1;
    }
    tf.content = new_content;
    tf.cursor_pos = pos + 1;
    return tf.content;
}

def bring_to_front(window_id: str, next_z: int) -> int | None {
    fw = root spawn Finder(target=window_id, claimed={});
    if fw.hit_win is None { return None; }
    win = fw.hit_win;
    assigned: int = next_z;
    if assigned >= OVERLAY_Z_THRESHOLD { assigned = MAX_SAFE_Z; }
    win.z_order = assigned;
    win.local_z = assigned;
    return assigned;
}

with entry {
    graph_root = UINode(cid="demo", layout_dirty=True);
    root ++> graph_root;
    panel = UINode(cid="panel");
    graph_root +>:Child:+> panel;
    tf = TextField(cid="field", content="", cursor_pos=5);
    root ++> tf;
    win = Window(cid="win");
    root ++> win;
    root spawn Finder(target="demo", claimed={});
    print([
        "demo",
        relayout_subtree("demo", False),
        insert_text_clamped("field", "x"),
        bring_to_front("win", 1200),
    ]);
}
