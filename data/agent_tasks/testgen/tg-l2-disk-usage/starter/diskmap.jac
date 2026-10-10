"""Folder/File containment tree with size and extension walkers."""

node Folder {
    has name: str;
}

node File {
    has name: str;
    has size: int = 0;
}

walker DiskUsage {
    has total: int = 0;

    can into with Folder entry {
        visit [-->];
    }

    can count with File entry {
        self.total += here.size;
    }

    can finish with exit {
        report self.total;
    }
}

def size_desc_then_path(t: tuple[int, str]) -> tuple[int, str] {
    return (-t[0], t[1]);
}

walker LargeFiles {
    has min_size: int = 0;
    has paths: dict[str, str] = {};
    has found: list[tuple[int, str]] = [];

    can into with Folder entry {
        here_path = self.paths.get(jid(here), here.name);
        for child in [here -->[?:Folder]] {
            self.paths[jid(child)] = here_path + "/" + child.name;
        }
        for f in [here -->[?:File]] {
            self.paths[jid(f)] = here_path + "/" + f.name;
        }
        visit [-->];
    }

    can check with File entry {
        if here.size >= self.min_size {
            self.found.append((here.size, self.paths[jid(here)]));
        }
    }

    can finish with exit {
        ordered = sorted(self.found, key=size_desc_then_path);
        report [p for (_, p) in ordered];
    }
}

def extension_of(name: str) -> str {
    stem = name.lstrip(".");
    if "." not in stem {
        return "";
    }
    return stem.rsplit(".", 1)[1].lower();
}

walker ExtensionCounts {
    has counts: dict[str, int] = {};

    can into with Folder entry {
        visit [-->];
    }

    can count with File entry {
        ext = extension_of(here.name);
        self.counts[ext] = self.counts.get(ext, 0) + 1;
    }

    can finish with exit {
        report self.counts;
    }
}
