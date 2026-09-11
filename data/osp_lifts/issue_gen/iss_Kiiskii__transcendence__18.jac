node Category { has cid: str; has slug: str; has cname: str; has parent_cid: str = ""; }
node Listing { has lid: str; has title: str; has category_slug: str; }
node Tag { has tname: str; }
node GraphRoot { has rid: str = "root"; }
edge Subcat {}
edge ListingCat {}
edge ListingTag {}
walker CategoryClosure {
    has claimed: dict[str, bool] = {};
    has slugs: list[str] = [];
    can traverse with Category entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.slugs.append(here.slug);
        print(here.slug);
        for ch in [here ->:Subcat:->][?:Category] { visit :0: [ch]; }
    }
}
walker ListingByCategory {
    has target_slugs: list[str] = [];
    has found: list[Listing] = [];
    has claimed: dict[str, bool] = {};
    can scan_root with GraphRoot entry {
        for nd in [here -->][?:Listing] { visit :0: [nd]; }
    }
    can collect with Listing entry {
        if here.lid in self.claimed { skip; }
        self.claimed[here.lid] = True;
        print(here.lid);
        for s in self.target_slugs { if here.category_slug == s { self.found.append(here); break; } }
    }
}
walker ListingsByTag {
    has target: str = "";
    has found: list[Listing] = [];
    has claimed: dict[str, bool] = {};
    can scan_root with GraphRoot entry {
        for nd in [here -->][?:Listing] { visit :0: [nd]; }
    }
    can check with Listing entry {
        if here.lid in self.claimed { skip; }
        self.claimed[here.lid] = True;
        print(here.lid);
        for tg in [here ->:ListingTag:->][?:Tag] { if tg.tname == self.target { self.found.append(here); break; } }
    }
}
walker DemoWalker {
    has out: list[str] = [];
    has claimed: dict[str, bool] = {};
    can demo_a with Category entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.out.append(here.slug);
        print(here.slug);
        for ch in [here ->:Subcat:->][?:Category] { visit :0: [ch]; }
    }
    can demo_b with Listing entry {
        if here.lid in self.claimed { skip; }
        self.claimed[here.lid] = True;
        print(here.title);
    }
}
def find_category(graph_root: GraphRoot, slug: str) -> Category | None {
    for c in [graph_root -->][?:Category] { if c.slug == slug { return c; } }
    return None;
}
def create_category(graph_root: GraphRoot, cid: str, slug: str, cname: str, parent_slug: str | None = None) -> Category | None {
    for c in [graph_root -->][?:Category] { if c.cid == cid { return None; } if c.slug == slug { return None; } }
    parent: Category | None = None;
    parent_cid: str = "";
    if parent_slug is not None {
        for c in [graph_root -->][?:Category] { if c.slug == parent_slug { parent = c; break; } }
        if parent is None { return None; }
        p: Category = parent as Category;
        if p.parent_cid != "" { return None; }
        parent_cid = p.cid;
    }
    cat: Category = Category(cid=cid, slug=slug, cname=cname, parent_cid=parent_cid);
    graph_root ++> cat;
    if parent is not None { p2: Category = parent as Category; p2 +>:Subcat:+> cat; }
    return cat;
}
def create_listing(graph_root: GraphRoot, lid: str, title: str, category_slug: str, tags: list[str]) -> Listing | None {
    for lst in [graph_root -->][?:Listing] { if lst.lid == lid { return None; } }
    cat: Category | None = find_category(graph_root, category_slug);
    if cat is None { return None; }
    normed: list[str] = [];
    seen: dict[str, bool] = {};
    for t in tags {
        tmp: str = t.strip();
        cleaned: str = tmp.lower();
        if cleaned == "" { continue; }
        if cleaned in seen { continue; }
        seen[cleaned] = True;
        normed.append(cleaned);
        if len(normed) >= 5 { break; }
    }
    lst: Listing = Listing(lid=lid, title=title, category_slug=category_slug);
    graph_root ++> lst;
    cn: Category = cat as Category;
    lst +>:ListingCat:+> cn;
    for tn in normed {
        tg: Tag | None = None;
        for ex in [graph_root -->][?:Tag] { if ex.tname == tn { tg = ex; break; } }
        if tg is None { nt: Tag = Tag(tname=tn); graph_root ++> nt; tg = nt; }
        tnode: Tag = tg as Tag;
        lst +>:ListingTag:+> tnode;
    }
    return lst;
}
def get_listings_by_category(graph_root: GraphRoot, slug: str) -> list[Listing] {
    target: Category | None = find_category(graph_root, slug);
    if target is None { return []; }
    tcat: Category = target as Category;
    cw: CategoryClosure = tcat spawn CategoryClosure(claimed={}, slugs=[]);
    closure: list[str] = cw.slugs;
    lw: ListingByCategory = graph_root spawn ListingByCategory(target_slugs=closure, found=[], claimed={});
    return lw.found;
}
def get_listings_by_tag(graph_root: GraphRoot, tag: str) -> list[Listing] {
    tmp: str = tag.strip();
    cleaned: str = tmp.lower();
    if cleaned == "" { return []; }
    lw: ListingsByTag = graph_root spawn ListingsByTag(target=cleaned, found=[], claimed={});
    return lw.found;
}
def list_categories(graph_root: GraphRoot) -> list[str] {
    out: list[str] = [];
    for c in [graph_root -->][?:Category] { out.append(c.slug); }
    return out;
}
with entry {
    gr: GraphRoot = GraphRoot();
    root ++> gr;
    c: Category = Category(cid="d0", slug="mushrooms", cname="Mushrooms");
    gr ++> c;
    w: DemoWalker = root spawn DemoWalker(out=[], claimed={});
    print(w.out);
}
