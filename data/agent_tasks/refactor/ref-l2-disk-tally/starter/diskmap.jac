"""Folder tree with file sizes; folders are addressed by slash paths like "home/ana"."""

node Folder {
    has path: str;
}

node File {
    has name: str;
    has size: int;
}

def _folder(path: str) -> Folder | None {
    for n in [root -->] {
        if isinstance(n, Folder) and n.path == path {
            return n;
        }
    }
    return None;
}

def add_folder(path: str) -> bool {
    if _folder(path) is not None {
        return False;
    }
    parent: Folder | None = None;
    if "/" in path {
        parent = _folder(path.rsplit("/", 1)[0]);
        if parent is None {
            return False;
        }
    }
    f = Folder(path=path);
    root ++> f;
    if parent is not None {
        parent ++> f;
    }
    return True;
}

def add_file(folder: str, name: str, size: int) -> bool {
    d = _folder(folder);
    if d is None {
        return False;
    }
    for c in [d -->] {
        if isinstance(c, File) and c.name == name {
            return False;
        }
    }
    d ++> File(name=name, size=size);
    return True;
}

def _total(d: Folder) -> int {
    total = 0;
    for c in [d -->] {
        if isinstance(c, File) {
            total += c.size;
        } elif isinstance(c, Folder) {
            total += _total(c);
        }
    }
    return total;
}

def _count(d: Folder) -> int {
    n = 0;
    for c in [d -->] {
        if isinstance(c, File) {
            n += 1;
        } elif isinstance(c, Folder) {
            n += _count(c);
        }
    }
    return n;
}

def _collect(d: Folder, min_size: int, out: list[str]) {
    for c in [d -->] {
        if isinstance(c, File) {
            if c.size >= min_size {
                out.append(d.path + "/" + c.name);
            }
        } elif isinstance(c, Folder) {
            _collect(c, min_size, out);
        }
    }
}

def usage(path: str) -> int {
    d = _folder(path);
    if d is None {
        return 0;
    }
    return _total(d);
}

def file_count(path: str) -> int {
    d = _folder(path);
    if d is None {
        return 0;
    }
    return _count(d);
}

def big_files(path: str, min_size: int) -> list[str] {
    d = _folder(path);
    if d is None {
        return [];
    }
    out: list[str] = [];
    _collect(d, min_size, out);
    return sorted(out);
}
