# MatthewMckee4/gdsr#297

node Cell {
    has cid: str;
    has name: str;
    has width: int = 0;
    has height: int = 0;
}

edge Contains {}

obj Library {
    has cells: list[Cell] = [];
}

walker Collect {
    has claimed: dict[str, bool] = {};
    has items: list[str] = [];

    can collect with Cell entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.items.append(here.cid);
        print("collect " + here.cid);
        for child in [here ->:Contains:->][?:Cell] {
            visit :0: [child];
        }
    }
}

walker CycleProbe {
    has target: str;
    has claimed: dict[str, bool] = {};
    has routes: dict[str, list[str]] = {};
    has path: list[str] = [];

    can probe with Cell entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("probe " + here.cid);
        if here.cid == self.target {
            self.path = [self.target];
            for cid in self.routes[here.cid] {
                self.path.append(cid);
            }
        }
        for child in [here ->:Contains:->][?:Cell] {
            if child.cid not in self.routes {
                self.routes[child.cid] =
                    self.routes[here.cid] + [child.cid];
            }
            visit :0: [child];
        }
    }
}

def _find(lib: Library, cid: str) -> Cell | None {
    for cell in lib.cells {
        if cell.cid == cid {
            return cell;
        }
    }
    return None;
}

def _cycle_path(parent: Cell, child: Cell) -> list[str] {
    routes: dict[str, list[str]] = {};
    routes[child.cid] = [child.cid];
    w = child spawn CycleProbe(
        target=parent.cid, claimed={}, routes=routes
    );
    return w.path;
}

def add_cell(lib: Library, cid: str, name: str) -> bool {
    if _find(lib, cid) is not None {
        return False;
    }
    cell = Cell(cid=cid, name=name);
    lib.cells.append(cell);
    return True;
}

def insert_reference(
    lib: Library, parent_id: str, child_id: str
) -> list[str] {
    parent: Cell | None = _find(lib, parent_id);
    child: Cell | None = _find(lib, child_id);
    if parent is None or child is None {
        return [];
    }
    cycle = _cycle_path(parent, child);
    if len(cycle) > 0 {
        return cycle;
    }
    parent +>:Contains:+> child;
    return [];
}

def copy_subtree(lib: Library, source_id: str, parent_id: str) -> bool {
    if _find(lib, source_id) is None or _find(lib, parent_id) is None {
        return False;
    }
    return len(insert_reference(lib, parent_id, source_id)) == 0;
}

def rename_update(lib: Library, cid: str, new_name: str) -> bool {
    cell: Cell | None = _find(lib, cid);
    if cell is None {
        return False;
    }
    cell.name = new_name;
    return True;
}

def recursive_iter(lib: Library, start_id: str) -> list[str] {
    start: Cell | None = _find(lib, start_id);
    if start is None {
        return [];
    }
    claimed: dict[str, bool] = {};
    items: list[str] = [];
    w = start spawn Collect(claimed=claimed, items=items);
    return w.items;
}

def flatten(lib: Library) -> list[str] {
    claimed: dict[str, bool] = {};
    items: list[str] = [];
    for cell in lib.cells {
        w = cell spawn Collect(claimed=claimed, items=items);
        claimed = w.claimed;
        items = w.items;
    }
    return items;
}

def has_circular_references(lib: Library) -> bool {
    for cell in lib.cells {
        for child in [cell ->:Contains:->][?:Cell] {
            if len(_cycle_path(cell, child)) > 0 {
                return True;
            }
        }
    }
    return False;
}

def bounds(lib: Library) -> dict[str, int] {
    ids = flatten(lib);
    max_width: int = 0;
    max_height: int = 0;
    for cid in ids {
        cell: Cell | None = _find(lib, cid);
        if cell is not None {
            if cell.width > max_width {
                max_width = cell.width;
            }
            if cell.height > max_height {
                max_height = cell.height;
            }
        }
    }
    return {"width": max_width, "height": max_height};
}

def stats(lib: Library) -> dict[str, int] {
    ids = flatten(lib);
    references: int = 0;
    for cell in lib.cells {
        for child in [cell ->:Contains:->][?:Cell] {
            if child.cid in ids {
                references += 1;
            }
        }
    }
    return {"cells": len(ids), "references": references};
}

def merge(dst: Library, src: Library) -> bool {
    if has_circular_references(src) {
        return False;
    }
    for source_cell in src.cells {
        if _find(dst, source_cell.cid) is not None {
            return False;
        }
    }
    copies: dict[str, Cell] = {};
    for source_cell in src.cells {
        copy = Cell(
            cid=source_cell.cid,
            name=source_cell.name,
            width=source_cell.width,
            height=source_cell.height
        );
        copies[source_cell.cid] = copy;
        dst.cells.append(copy);
    }
    for source_cell in src.cells {
        for child in [source_cell ->:Contains:->][?:Cell] {
            insert_reference(dst, source_cell.cid, child.cid);
        }
    }
    return True;
}

test "diamond revisit" {
    lib = Library();
    a = Cell(cid="a", name="A", width=2, height=3);
    b = Cell(cid="b", name="B", width=4, height=1);
    c = Cell(cid="c", name="C", width=3, height=6);
    d = Cell(cid="d", name="D", width=7, height=2);
    lib.cells.append(a);
    lib.cells.append(b);
    lib.cells.append(c);
    lib.cells.append(d);
    a +>:Contains:+> b;
    a +>:Contains:+> c;
    b +>:Contains:+> d;
    c +>:Contains:+> d;
    assert (has_circular_references(lib) == False);
    assert (sorted(recursive_iter(lib, "a")) == ["a", "b", "c", "d"]);
    assert (sorted(flatten(lib)) == ["a", "b", "c", "d"]);
    assert (bounds(lib)["width"] == 7);
    assert (bounds(lib)["height"] == 6);
    assert (stats(lib)["references"] == 4);
}

test "rejects indirect cycle atomically" {
    lib = Library();
    assert (add_cell(lib, "a", "A"));
    assert (add_cell(lib, "b", "B"));
    assert (add_cell(lib, "c", "C"));
    a = lib.cells[0];
    b = lib.cells[1];
    c = lib.cells[2];
    a +>:Contains:+> b;
    b +>:Contains:+> c;
    before = stats(lib);
    cycle = insert_reference(lib, "c", "a");
    assert (cycle == ["c", "a", "b", "c"]);
    assert (stats(lib) == before);
    assert (copy_subtree(lib, "a", "c") == False);
    assert (rename_update(lib, "b", "renamed") == True);
}

test "unknown identifiers are tolerated" {
    lib = Library();
    assert (insert_reference(lib, "missing", "other") == []);
    assert (copy_subtree(lib, "missing", "other") == False);
    assert (rename_update(lib, "missing", "unused") == False);
    assert (recursive_iter(lib, "missing") == []);
    assert (flatten(lib) == []);
    assert (has_circular_references(lib) == False);
}

test "recursive operations terminate on existing cycle" {
    lib = Library();
    a = Cell(cid="a", name="A");
    b = Cell(cid="b", name="B");
    c = Cell(cid="c", name="C");
    lib.cells.append(a);
    lib.cells.append(b);
    lib.cells.append(c);
    a +>:Contains:+> b;
    b +>:Contains:+> c;
    c +>:Contains:+> a;
    assert (has_circular_references(lib) == True);
    assert (sorted(recursive_iter(lib, "a")) == ["a", "b", "c"]);
    assert (sorted(flatten(lib)) == ["a", "b", "c"]);
    assert (stats(lib)["cells"] == 3);
    assert (stats(lib)["references"] == 3);
}
