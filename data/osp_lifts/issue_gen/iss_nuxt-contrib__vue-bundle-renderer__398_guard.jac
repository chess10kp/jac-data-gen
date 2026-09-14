node Chunk {
    has cid: str;
    has file: str;
    has resourceType: str;
    has css: list[str] = [];
}

edge Import {}

node ManifestGraph {
    has chunks: dict[str, Chunk] = {};
}

walker DependencyWalk {
    has claimed: dict[str, bool] = {};
    has scripts: dict[str, bool] = {};
    has styles: dict[str, bool] = {};
    has preload: dict[str, bool] = {};
    has prefetch: dict[str, bool] = {};

    can step with Chunk entry {
        if here.cid in self.claimed {
            skip;
        }
        self.claimed[here.cid] = True;

        if here.resourceType == "script" {
            self.scripts[here.file] = True;
        }
        if here.resourceType == "style" {
            self.styles[here.file] = True;
        }
        for css_file in here.css {
            self.styles[css_file] = True;
        }
        print(here.cid);

        for child in [here ->:Import:->][?:Chunk] {
            visit :0: [child];
        }
    }
}

def precomputeDependencies(
    manifest: dict[str, dict[str, any]]
) -> dict[str, any] {
    graph_node = ManifestGraph();

    for module_id in manifest {
        meta: dict[str, any] = manifest[module_id] as dict[str, any];
        file_name: str = meta["file"] as str;
        resource_type: str = meta["resourceType"] as str;
        css_files: list[str] = [];
        imports: list[str] = [];

        if "css" in meta {
            css_files = meta["css"] as list[str];
        }
        if "imports" in meta {
            imports = meta["imports"] as list[str];
        }

        chunk = Chunk(
            cid=module_id,
            file=file_name,
            resourceType=resource_type,
            css=css_files
        );
        graph_node.chunks[module_id] = chunk;
    }

    for module_id in manifest {
        meta: dict[str, any] = manifest[module_id] as dict[str, any];
        imports: list[str] = [];
        if "imports" in meta {
            imports = meta["imports"] as list[str];
        }

        source: Chunk = graph_node.chunks[module_id];
        for imported_id in imports {
            if imported_id in graph_node.chunks {
                target: Chunk = graph_node.chunks[imported_id];
                source +>:Import:+> target;
            }
        }
    }

    dependencies: dict[str, dict[str, any]] = {};
    for module_id in manifest {
        w = graph_node.chunks[module_id] spawn DependencyWalk(claimed={});
        dependency: dict[str, any] = {};
        dependency["scripts"] = w.scripts;
        dependency["styles"] = w.styles;
        dependency["preload"] = w.preload;
        dependency["prefetch"] = w.prefetch;
        dependencies[module_id] = dependency;
    }

    return {"dependencies": dependencies};
}

test "cycle_styles_are_order_independent" {
    manifest_a: dict[str, dict[str, any]] = {};
    manifest_a["a.js"] = {"file": "a.js", "resourceType": "script", "css": [], "imports": ["_shared.js"]};
    manifest_a["_shared.js"] = {"file": "shared.js", "resourceType": "script", "css": ["shared.css"], "imports": ["b.js"]};
    manifest_a["b.js"] = {"file": "b.js", "resourceType": "script", "css": [], "imports": ["a.js"]};
    manifest_a["shared.css"] = {"file": "shared.css", "resourceType": "style", "css": [], "imports": []};

    out_a = precomputeDependencies(manifest_a);
    deps_a: dict[str, dict[str, any]] = out_a["dependencies"] as dict[str, dict[str, any]];
    assert ("shared.css" in (deps_a["a.js"]["styles"] as dict[str, bool]));
    assert ("shared.css" in (deps_a["_shared.js"]["styles"] as dict[str, bool]));
    assert ("shared.css" in (deps_a["b.js"]["styles"] as dict[str, bool]));

    manifest_b: dict[str, dict[str, any]] = {};
    manifest_b["b.js"] = {"file": "b.js", "resourceType": "script", "css": [], "imports": ["a.js"]};
    manifest_b["a.js"] = {"file": "a.js", "resourceType": "script", "css": [], "imports": ["_shared.js"]};
    manifest_b["_shared.js"] = {"file": "shared.js", "resourceType": "script", "css": ["shared.css"], "imports": ["b.js"]};
    manifest_b["shared.css"] = {"file": "shared.css", "resourceType": "style", "css": [], "imports": []};

    out_b = precomputeDependencies(manifest_b);
    deps_b: dict[str, dict[str, any]] = out_b["dependencies"] as dict[str, dict[str, any]];
    assert ("shared.css" in (deps_b["a.js"]["styles"] as dict[str, bool]));
    assert ("shared.css" in (deps_b["_shared.js"]["styles"] as dict[str, bool]));
    assert ("shared.css" in (deps_b["b.js"]["styles"] as dict[str, bool]));
}

test "diamond_revisit_keeps_transitive_styles" {
    manifest: dict[str, dict[str, any]] = {};
    manifest["root.js"] = {"file": "root.js", "resourceType": "script", "css": [], "imports": ["left.js", "right.js"]};
    manifest["left.js"] = {"file": "left.js", "resourceType": "script", "css": [], "imports": ["shared.js"]};
    manifest["right.js"] = {"file": "right.js", "resourceType": "script", "css": [], "imports": ["shared.js", "tail.js"]};
    manifest["shared.js"] = {"file": "shared.js", "resourceType": "script", "css": ["diamond.css"], "imports": []};
    manifest["tail.js"] = {"file": "tail.js", "resourceType": "script", "css": ["tail.css"], "imports": []};

    out = precomputeDependencies(manifest);
    deps: dict[str, dict[str, any]] = out["dependencies"] as dict[str, dict[str, any]];
    styles: dict[str, bool] = deps["root.js"]["styles"] as dict[str, bool>;
    assert ("diamond.css" in styles);
    assert ("tail.css" in styles);
    assert (len(styles) == 2);
}

test "unknown_imports_are_ignored" {
    manifest: dict[str, dict[str, any]] = {};
    manifest["entry.js"] = {"file": "entry.js", "resourceType": "script", "css": ["entry.css"], "imports": ["missing.js"]};

    out = precomputeDependencies(manifest);
    deps: dict[str, dict[str, any]] = out["dependencies"] as dict[str, dict[str, any>>;
    styles: dict[str, bool] = deps["entry.js"]["styles"] as dict[str, bool>;
    assert (len(deps) == 1);
    assert ("entry.css" in styles);
}

test "empty_and_self_cycle_inputs_are_safe" {
    empty: dict[str, dict[str, any]] = {};
    empty_out = precomputeDependencies(empty);
    empty_deps: dict[str, dict[str, any]] = empty_out["dependencies"] as dict[str, dict[str, any>>;
    assert (len(empty_deps) == 0);

    self_cycle: dict[str, dict[str, any]] = {};
    self_cycle["loop.js"] = {"file": "loop.js", "resourceType": "script", "css": ["loop.css"], "imports": ["loop.js"]};
    loop_out = precomputeDependencies(self_cycle);
    loop_deps: dict[str, dict[str, any]] = loop_out["dependencies"] as dict[str, dict[str, any>>;
    loop_styles: dict[str, bool] = loop_deps["loop.js"]["styles"] as dict[str, bool>;
    assert ("loop.css" in loop_styles);
    assert (len(loop_styles) == 1);
}
