"""Folder tree with file sizes; folders are addressed by slash paths like "home/ana"."""

node Folder {
    has path: str;
}

node File {
    has name: str;
    has size: int;
}

"""Spawned on a folder: walks it and every subfolder, tallying the files it meets."""
walker Tally {
    has min_size: int = 0;
    has total: int = 0;
    has files: int = 0;
    has big: list[str] = [];

    can scan with Folder entry {
        for f in [here -->[?:File]] {
            self.total += f.size;
            self.files += 1;
            if f.size >= self.min_size {
                self.big.append(here.path + "/" + f.name);
            }
        }
        visit [here -->[?:Folder]];
    }
}

def find_folder(path: str) -> Folder | None {
    wanted = path;
    found = [root -->[?:Folder, path == wanted]];
    return found[0] if found else None;
}

def add_folder(path: str) -> bool {
    if find_folder(path) is not None {
        return False;
    }
    parent: Folder | None = None;
    if "/" in path {
        parent = find_folder(path.rsplit("/", 1)[0]);
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
    d = find_folder(folder);
    if d is None {
        return False;
    }
    wanted = name;
    if [d -->[?:File, name == wanted]] {
        return False;
    }
    d ++> File(name=name, size=size);
    return True;
}

def tally(path: str, min_size: int) -> Tally | None {
    d = find_folder(path);
    if d is None {
        return None;
    }
    return d spawn Tally(min_size=min_size);
}

def usage(path: str) -> int {
    t = tally(path, 0);
    return t.total if t is not None else 0;
}

def file_count(path: str) -> int {
    t = tally(path, 0);
    return t.files if t is not None else 0;
}

def big_files(path: str, min_size: int) -> list[str] {
    t = tally(path, min_size);
    return sorted(t.big) if t is not None else [];
}
