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
