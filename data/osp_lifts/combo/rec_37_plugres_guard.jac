"""Guard suite for rec_37_plugres."""
import from rec_37_plugres { PluginRegistry }

def fresh() -> PluginRegistry {
    return build_with(pylint_pinned=False);
}

def build_with(pylint_pinned: bool) -> PluginRegistry {
    r = PluginRegistry();
    r.add_group("tools");
    r.add_group("linters", parent="tools");
    r.add_group("themes", parent="tools");
    r.add_plugin("core", "tools");
    r.add_plugin("pylint", "linters", pinned=pylint_pinned);
    r.add_plugin("flake8", "linters");
    r.add_plugin("dark", "themes");
    r.require("pylint", "core");
    r.require("flake8", "core");
    return r;
}

test "structure and group tallies" {
    r = fresh();
    assert sorted([r.by_gid[g].gid for g in r.by_gid]) == ["linters", "themes", "tools"];
    assert r.group_load("tools") == 4;
    assert r.group_load("linters") == 2;
    threw_dup = False;
    try {
        r.add_group("tools");
    } except ValueError as ex {
        threw_dup = True;
    }
    assert threw_dup;
    threw_gid = False;
    try {
        r.add_plugin("x", "ghost");
    } except KeyError as ex {
        threw_gid = True;
    }
    assert threw_gid;
}

test "cascade removes transitive dependents once only" {
    r = fresh();
    assert r.dependents_of("core") == ["flake8", "pylint"];
    removed = r.uninstall("core");
    assert len(removed) == len(set(removed));
    assert removed == ["core", "flake8", "pylint"];
    assert "dark" in r.by_pid;
    assert r.group_load("tools") == 1;
    assert r.dependents_of("core") == [];
}

test "diamond dependents survive revisits" {
    r = fresh();
    # diamond: app depends on web and cli; both depend on core
    r.add_plugin("web", "tools");
    r.add_plugin("cli", "tools");
    r.add_plugin("app", "tools");
    r.require("app", "web");
    r.require("app", "cli");
    r.require("web", "core");
    r.require("cli", "core");
    removed = r.uninstall("core");
    assert len(removed) == len(set(removed));
    assert removed == ["app", "cli", "core", "flake8", "pylint", "web"];
}

test "pinned branch pruned, force overrides" {
    r = build_with(pylint_pinned=True);
    removed = r.uninstall("core");
    assert removed == ["core", "flake8"];  # pylint spared with its branch
    assert "pylint" in r.by_pid;
    forced = build_with(pylint_pinned=True);
    assert forced.uninstall("core", force=True) == ["core", "flake8", "pylint"];
    pinned_root = fresh();
    pinned_root.add_plugin("dark2", "themes", pinned=True);
    assert pinned_root.uninstall("dark2") == [];
    assert pinned_root.uninstall("dark2", force=True) == ["dark2"];
}

test "unknown plugin raises" {
    r = fresh();
    threw = False;
    try {
        r.uninstall("ghost");
    } except KeyError as ex {
        threw = True;
    }
    assert threw;
}
