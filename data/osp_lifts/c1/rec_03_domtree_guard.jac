"""DOM-like document tree lifted to OSP.

Elements are ``Element`` nodes; ``NestedIn`` edges point from an
element to its parent. Depth queries climb; selector sweeps collect
on typed walker fields; outline rendering keeps the source's
``MAX_OUTLINE_DEPTH`` cap as explicit walker logic.
"""

glob MAX_OUTLINE_DEPTH = 3;

node Element {
    has tag: str;
    has el_id: str;
    has width: int = 0;      # staging: subtree element count folded at exit
    has el_depth: int = 0;   # staging: deepest line below, folded at exit
    has top_depth: int = 0;  # staging: hops below base, stamped breadth-first
}

edge NestedIn: Element --> Element {}

"""Build the fixture document deterministically; returns the root element."""
def build_doc() -> Element {
    root ++> (doc := Element(tag="html", el_id="d0"));
    root ++> (body := Element(tag="body", el_id="d1"));
    root ++> (div_a := Element(tag="div", el_id="a"));
    root ++> (div_b := Element(tag="div", el_id="b"));
    root ++> (span1 := Element(tag="span", el_id="s1"));
    root ++> (p1 := Element(tag="p", el_id="p1"));
    root ++> (sec1 := Element(tag="section", el_id="sec1"));
    body +>:NestedIn:+> doc;
    div_a +>:NestedIn:+> body;
    div_b +>:NestedIn:+> body;
    span1 +>:NestedIn:+> div_a;
    p1 +>:NestedIn:+> span1;
    sec1 +>:NestedIn:+> p1;
    return doc;
}

"""Attach a new element to `parent_el` (None for the document root)."""
def append_child(parent_el: Element | None, tag: str, el_id: str) -> Element {
    root ++> (el := Element(tag=tag, el_id=el_id));
    if parent_el is not None {
        el +>:NestedIn:+> parent_el;
    }
    return el;
}

walker DepthClimb {
    """Climbs NestedIn edges to the document root; linear walk."""
    has stops: int = 0;
    has claimed: dict[str, bool] = {};

    can climb with Element entry {
        if here.el_id in self.claimed {
            skip;
        }
        self.claimed[here.el_id] = True;
        self.stops += 1;
        visit [->:NestedIn:->] else { report self.stops; disengage; }
    }
}

walker SelectorSweep {
    """Collects el_ids whose tag matches the wanted selector."""
    has want: str;
    has hits: list[str] = [];
    has claimed: dict[str, bool] = {};

    can sweep with Element entry {
        if here.el_id in self.claimed {
            skip;
        }
        self.claimed[here.el_id] = True;
        if here.tag == self.want {
            self.hits.append(here.el_id);
        }
        visit [<-:NestedIn:<-];
    }
}

walker DepthStamp {
    """Stamps each element's distance below the base.

    Walkers process entries breadth-first (a parent is always entered
    before its children), so the parent can stamp ``top_depth`` onto
    its children during its own entry ability.
    """
    has claimed: dict[str, bool] = {};
    has started: int = 0;

    can go with Element entry {
        if here.el_id in self.claimed {
            skip;
        }
        self.claimed[here.el_id] = True;
        if self.started == 0 {
            here.top_depth = 1;
            self.started = 1;
        }
        for c in [<-:NestedIn:<-] {
            c.top_depth = here.top_depth + 1;
        }
        visit [<-:NestedIn:<-];
    }
}

walker LabelSweep {
    """Collects labels of elements within MAX_OUTLINE_DEPTH of the base."""
    has labels: list[str] = [];
    has claimed: dict[str, bool] = {};

    can sweep with Element entry {
        if here.el_id in self.claimed {
            skip;
        }
        self.claimed[here.el_id] = True;
        if here.top_depth <= MAX_OUTLINE_DEPTH and here.top_depth > 0 {
            self.labels.append(f"{here.tag}#{here.el_id}");
        }
        visit [<-:NestedIn:<-];
    }
}

walker WidthFold {
    """Exit folds the subtree element count bottom-up."""
    has claimed: dict[str, bool] = {};

    can descend with Element entry {
        if here.el_id in self.claimed {
            skip;
        }
        self.claimed[here.el_id] = True;
        visit [<-:NestedIn:<-];
    }

    can fold with Element exit {
        total = 1;
        for c in [<-:NestedIn:<-] {
            total += c.width;
        }
        here.width = total;
    }
}

def element_depth(el: Element) -> int {
    w = el spawn DepthClimb();
    return w.stops;
}

def query_selector_all(el: Element, tag: str) -> list[str] {
    w = el spawn SelectorSweep(want=tag);
    return sorted(w.hits);
}

def render_outline(base: Element) -> list[str] {
    base spawn DepthStamp();
    w = base spawn LabelSweep();
    return sorted(w.labels);
}

def subtree_width(el: Element) -> int {
    el spawn WidthFold();
    return el.width;
}
test "element_depth climbs to document root" {
    doc = build_doc();
    body = [k for k in [doc <--][?:Element] if k.el_id == "d1"][0];
    sec1 = [k for k in [body <--][?:Element] if k.el_id == "a"][0];
    span1 = [k for k in [sec1 <--][?:Element]][0];
    p1 = [k for k in [span1 <--][?:Element]][0];
    sec_deep = [k for k in [p1 <--][?:Element]][0];
    assert element_depth(sec_deep) == 6;
    assert element_depth(doc) == 1;
}

test "query_selector_all matches tag multiset" {
    doc = build_doc();
    assert query_selector_all(doc, "div") == ["a", "b"];
    assert query_selector_all(doc, "canvas") == [];
}

test "render_outline respects depth cap" {
    doc = build_doc();
    outline = render_outline(doc);
    assert sorted(outline) == ["body#d1", "div#a", "div#b", "html#d0"];
}

test "subtree_width counts elements" {
    doc = build_doc();
    body = [k for k in [doc <--][?:Element] if k.el_id == "d1"][0];
    div_a = [k for k in [body <--][?:Element] if k.el_id == "a"][0];
    assert subtree_width(doc) == 7;
    assert subtree_width(div_a) == 4;
}
test "append_child extends the document" {
    doc = build_doc();
    body = [k for k in [doc <--][?:Element] if k.el_id == "d1"][0];
    fresh = append_child(body, "div", "z9");
    assert query_selector_all(doc, "div") == ["a", "b", "z9"];
    assert element_depth(fresh) == 3;
    assert subtree_width(doc) == 8;
    assert "div#z9" in render_outline(doc);
}
