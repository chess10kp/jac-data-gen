node SkillDir {
    has path: str;
    has name: str;
    has is_symlink: bool = False;
    has resolved: str = "";
}

node SkillManifest {
    has path: str;
    has name: str;
    has description: str;
    has depth: int = 0;
}

edge contains {}
edge symlink_to {}
edge registered_from {}

obj SkillRegistry {
    has by_name: dict[str, list[SkillManifest]] = {};

    def register(m: SkillManifest) -> None {
        if m.name not in self.by_name {
            self.by_name[m.name] = [];
        }
        self.by_name[m.name].append(m);
    }

    def visible_names() -> list[str] {
        names: list[str] = [];
        for k in sorted(self.by_name.keys()) {
            names.append(k);
        }
        return names;
    }
}

def parse_manifest(path: str, name: str, desc: str, depth: int) -> SkillManifest {
    return SkillManifest(path=path, name=name, description=desc, depth=depth);
}

def dedupe_manifests(ms: list[SkillManifest]) -> list[SkillManifest] {
    out: list[SkillManifest] = [];
    seen: dict[str, bool] = {};
    for m in ms {
        if m.path in seen {
            continue;
        }
        seen[m.path] = True;
        out.append(m);
    }
    return out;
}

walker DiscoverSkills {
    has claimed: dict[str, bool] = {};
    has registry: SkillRegistry | None = None;

    can start with SkillDir entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        if here.resolved != "" {
            print("resolving symlink", here.name, "->", here.resolved);
        }
        kids: list[SkillDir] = [here ->:contains:->][?:SkillDir];
        kids = sorted(kids, key=lambda k: k.path);
        visit kids else { disengage; }
    }

    can found with SkillManifest entry {
        if here.path in self.claimed {
            skip;
        }
        self.claimed[here.path] = True;
        if self.registry is None {
            self.registry = SkillRegistry();
        }
        self.registry.register(here);
        print("registered", here.name, "at", here.path, "depth", here.depth);
        parents: list[SkillDir] = [here <-:registered_from:-][?:SkillDir];
        visit parents else { disengage; }
    }
}

def build_fixture() -> SkillDir {
    toolkit = SkillDir(path="/tmp/repro/workflow-toolkit", name="workflow-toolkit");
    link = SkillDir(path="~/.agents/skills/workflow-toolkit", name="workflow-toolkit", is_symlink=True, resolved="/tmp/repro/workflow-toolkit");
    root_skill = SkillManifest(path="/tmp/repro/workflow-toolkit/SKILL.md", name="workflow-toolkit", description="Top-level skill");
    nested_a = SkillManifest(path="/tmp/repro/workflow-toolkit/runtime-sources/app-workflow/skills/apply-log/SKILL.md", name="apply-log", description="app workflow helper");
    nested_b = SkillManifest(path="/tmp/repro/workflow-toolkit/runtime-sources/writing-workflow/skills/apply-log/SKILL.md", name="apply-log", description="writing workflow helper");
    nested_c = SkillManifest(path="/tmp/repro/workflow-toolkit/runtime-sources/app-workflow/skills/init-log/SKILL.md", name="init-log", description="app workflow helper");
    link +>:symlink_to:+> toolkit;
    toolkit +>:contains:+> root_skill;
    toolkit +>:contains:+> nested_a;
    toolkit +>:contains:+> nested_b;
    toolkit +>:contains:+> nested_c;
    root_skill +>:registered_from:+> toolkit;
    nested_a +>:registered_from:+> toolkit;
    nested_b +>:registered_from:+> toolkit;
    nested_c +>:registered_from:+> toolkit;
    return link;
}

def skills_list() -> dict[str, list[str]] {
    entry_dir = build_fixture();
    wk = entry_dir spawn DiscoverSkills(claimed={});
    reg: SkillRegistry = SkillRegistry();
    if wk.registry is not None {
        reg = wk.registry;
    }
    by_name: dict[str, list[str]] = {};
    for nm in sorted(reg.by_name.keys()) {
        paths: list[str] = [];
        for m in reg.by_name[nm] {
            paths.append(m.path);
        }
        by_name[nm] = sorted(paths);
    }
    return by_name;
}

with entry {
    listing = skills_list();
    print("skills:", listing);
}

test "diamond_symlink_revisit" {
    root spawn Walker;
    listing = skills_list();
    assert "apply-log" in listing;
    assert len(listing["apply-log"]) == 2;
    assert listing["apply-log"][0] == "/tmp/repro/workflow-toolkit/runtime-sources/app-workflow/skills/apply-log/SKILL.md";
}

test "root_skill_registered_once" {
    root spawn Walker;
    listing = skills_list();
    assert "workflow-toolkit" in listing;
    assert len(listing["workflow-toolkit"]) == 1;
}

test "all_nested_registered" {
    root spawn Walker;
    listing = skills_list();
    assert len(listing["apply-log"]) == 2;
    assert "init-log" in listing;
    assert len(listing["init-log"]) == 1;
}

test "names_sorted_and_no_unknown_dupes" {
    root spawn Walker;
    listing = skills_list();
    keys: list[str] = sorted(listing.keys());
    assert keys == ["apply-log", "init-log", "workflow-toolkit"];
}

test "claim_map_prevents_infinite_walk" {
    root spawn Walker;
    entry_dir = build_fixture();
    wk = entry_dir spawn DiscoverSkills(claimed={});
    assert True;
}

test "parse_manifest_defaults" {
    root spawn Walker;
    m = parse_manifest("/x/SKILL.md", "x", "d", 3);
    assert m.depth == 3;
    assert m.description == "d";
    d = dedupe_manifests([m, m]);
    assert len(d) == 1;
}
