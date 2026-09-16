# perl-semantic-analyzer ref: EffortlessMetrics/perl-lsp-swarm#7493
# Retire legacy reparsing WorkspaceIndex: analyzer derives per-file
# contributions from accepted parsed sources; ProjectModel owns cross-file.
# gen = -1 marks a purged (retired) file node.

node FileNode {
    has uri: str;
    gen: int = 0;
    symbols: list[str] = [];
    deps: list[str] = [];
}

edge DependsOn {}

edge Defines {}

node ProjectModel {
    has name: str;
    has accepted: dict[str, FileNode] = {};
}

walker IngestFile {
    has uri: str;
    has gen: int;
    has symbols: list[str];
    has deps: list[str];

    can ingest with ProjectModel entry {
        kids: list[FileNode] = [here ->:Defines:->][?:FileNode];
        target: FileNode | None = None;
        for k in kids {
            if k.uri == self.uri { target = k; }
        }
        if target is None {
            target = FileNode(uri=self.uri);
            here +>:Defines:+> target;
        }
        # accepted-generation rule: stale gens cannot publish
        if target.gen > self.gen {
            print("stale_rejected " + self.uri);
            disengage;
        }
        target.gen = self.gen;
        target.symbols = self.symbols;
        target.deps = self.deps;
        for d in self.deps {
            provider: FileNode | None = None;
            for k in [here ->:Defines:->][?:FileNode] {
                if d in k.symbols { provider = k; }
            }
            if provider is not None {
                target +>:DependsOn:+> provider;
            }
        }
        here.accepted[self.uri] = target;
        print("ingested " + self.uri);
    }
}

walker AnalyzeFile {
    has claimed: dict[str, bool] = {};
    has out: dict[str, list[str]] = {};

    can analyze with FileNode entry {
        if here.uri in self.claimed { skip; }
        self.claimed[here.uri] = True;
        reach: list[str] = [];
        for d in [here ->:DependsOn:->][?:FileNode] {
            if d.gen < 0 { continue; }
            reach.append(d.uri);
            visit [d];
        }
        self.out[here.uri] = sorted(reach);
    }
}

walker PurgeUri {
    has uri: str;

    can purge with ProjectModel entry {
        kids: list[FileNode] = [here ->:Defines:->][?:FileNode];
        for k in kids {
            if k.uri == self.uri {
                # retire: purge publishes nothing, contributes nothing
                k.gen = -1;
                k.symbols = [];
                k.deps = [];
            }
        }
        print("purged " + self.uri);
    }
}

def contribution(p: ProjectModel, uri: str) -> dict[str, list[str]] {
    # deterministic per-file closure via walker, no reparse
    f: FileNode | None = None;
    for k in [p ->:Defines:->][?:FileNode] {
        if k.uri == uri { f = k; }
    }
    if f is None or f.gen < 0 { return {}; }
    w = f spawn AnalyzeFile(claimed={}, out={});
    return w.out;
}

def lookup(p: ProjectModel, sym: str) -> list[str] {
    uris: list[str] = [];
    for k in [p ->:Defines:->][?:FileNode] {
        if k.gen >= 0 and sym in k.symbols { uris.append(k.uri); }
    }
    return sorted(uris);
}

with entry {
    pm = ProjectModel(name="demo");
    IngestFile(uri="file:///a.pm", gen=1, symbols=["A"], deps=["B"]) spawn pm;
    IngestFile(uri="file:///b.pm", gen=1, symbols=["B"], deps=[]) spawn pm;
    print(lookup(pm, "A"));
    print(contribution(pm, "file:///a.pm"));
}

test "ingest and lookup" {
    pm = ProjectModel(name="t1");
    IngestFile(uri="file:///a.pm", gen=1, symbols=["A"], deps=["B"]) spawn pm;
    IngestFile(uri="file:///b.pm", gen=1, symbols=["B"], deps=[]) spawn pm;
    assert lookup(pm, "A") == ["file:///a.pm"];
    assert lookup(pm, "B") == ["file:///b.pm"];
    assert lookup(pm, "Z") == [];
}

test "contribution closure" {
    pm = ProjectModel(name="t2");
    IngestFile(uri="file:///a.pm", gen=1, symbols=["A"], deps=["B"]) spawn pm;
    IngestFile(uri="file:///b.pm", gen=1, symbols=["B"], deps=["C"]) spawn pm;
    IngestFile(uri="file:///c.pm", gen=1, symbols=["C"], deps=[]) spawn pm;
    assert contribution(pm, "file:///a.pm") == {"file:///a.pm": ["file:///b.pm"], "file:///b.pm": ["file:///c.pm"], "file:///c.pm": []};
}

test "stale generation rejected" {
    pm = ProjectModel(name="t3");
    IngestFile(uri="file:///a.pm", gen=3, symbols=["A"], deps=[]) spawn pm;
    IngestFile(uri="file:///a.pm", gen=2, symbols=["Old"], deps=[]) spawn pm;
    assert lookup(pm, "Old") == [];
    assert lookup(pm, "A") == ["file:///a.pm"];
}

test "purged file contributes nothing" {
    pm = ProjectModel(name="t4");
    IngestFile(uri="file:///a.pm", gen=1, symbols=["A"], deps=["B"]) spawn pm;
    IngestFile(uri="file:///b.pm", gen=1, symbols=["B"], deps=[]) spawn pm;
    PurgeUri(uri="file:///b.pm") spawn pm;
    assert lookup(pm, "B") == [];
    assert contribution(pm, "file:///a.pm") == {"file:///a.pm": []};
    assert contribution(pm, "file:///b.pm") == {};
}

test "unknown uri tolerated" {
    pm = ProjectModel(name="t5");
    assert contribution(pm, "file:///missing.pm") == {};
    PurgeUri(uri="file:///missing.pm") spawn pm;
    assert lookup(pm, "A") == [];
}

test "diamond dependencies" {
    pm = ProjectModel(name="t6");
    IngestFile(uri="file:///top.pm", gen=1, symbols=["T"], deps=["L", "R"]) spawn pm;
    IngestFile(uri="file:///l.pm", gen=1, symbols=["L"], deps=["bot"]) spawn pm;
    IngestFile(uri="file:///r.pm", gen=1, symbols=["R"], deps=["bot"]) spawn pm;
    IngestFile(uri="file:///bot.pm", gen=1, symbols=["bot"], deps=[]) spawn pm;
    assert contribution(pm, "file:///top.pm") == {"file:///top.pm": ["file:///l.pm", "file:///r.pm"], "file:///l.pm": ["file:///bot.pm"], "file:///r.pm": ["file:///bot.pm"], "file:///bot.pm": []};
}
