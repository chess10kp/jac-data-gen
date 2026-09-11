# iss_nahisaho__aira-synapse__11.jac
# nahisaho/aira-synapse#11 - fix: await Stage V dictionary persistence before indexing success

node GraphRoot { has name: str = "g"; }
node DocNode { has did: str; has corpus: str; }
node TermNode { has tid: str; has text: str; }
node DictNode { has store: dict[str, str] = {}; has should_fail: bool = False; }
node LexiconBuilder { has graph_root: GraphRoot; has dict_node: DictNode; }
node LexiconBuildResult { has doc_id: str; has entries: dict[str, str] = {}; has success: bool = True; }

edge HasDoc {}
edge Contains {}

walker BuildCollectWalker {
    has claimed: dict[str, bool] = {};
    has collected: list[TermNode] = [];
    can collect_doc with DocNode entry {
        if here.did in self.claimed { skip; }
        self.claimed[here.did] = True;
        print(f"BuildWalker doc {here.did}");
        kids: list[TermNode] = [here ->:Contains:->][?:TermNode];
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
    can collect_term with TermNode entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        print(f"entry {here.tid}");
        self.collected.append(here);
        kids: list[TermNode] = [here ->:Contains:->][?:TermNode];
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

walker BackfillCollectWalker {
    has corpus_id: str;
    has claimed: dict[str, bool] = {};
    has collected: list[TermNode] = [];
    can bf_root with GraphRoot entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        print(f"backfill start {self.corpus_id}");
        docs: list[DocNode] = [here ->:HasDoc:->][?:DocNode];
        if len(docs) > 0 {
            visit :0: docs;
        } else {
            disengage;
        }
    }
    can bf_doc with DocNode entry {
        if here.did in self.claimed { skip; }
        self.claimed[here.did] = True;
        print(f"backfill doc {here.did}");
        if here.corpus == self.corpus_id {
            kids: list[TermNode] = [here ->:Contains:->][?:TermNode];
            if len(kids) > 0 {
                visit :0: kids;
            } else {
                disengage;
            }
        } else {
            disengage;
        }
    }
    can bf_term with TermNode entry {
        if here.tid in self.claimed { skip; }
        self.claimed[here.tid] = True;
        print(f"backfill entry {here.tid}");
        self.collected.append(here);
        disengage;
    }
}

def new_graph() -> GraphRoot {
    gr = GraphRoot(name="g");
    root ++> gr;
    print("new_graph");
    return gr;
}

def make_builder(graph_root: GraphRoot) -> LexiconBuilder {
    dn = DictNode(store={});
    graph_root ++> dn;
    b = LexiconBuilder(graph_root=graph_root, dict_node=dn);
    root ++> b;
    print("make_builder");
    return b;
}

def find_doc(graph_root: GraphRoot, did: str) -> DocNode | None {
    candidates: list[DocNode] = [graph_root ->:HasDoc:->][?:DocNode];
    for c in candidates {
        if c.did == did {
            return c;
        }
    }
    return None;
}

def add_document(graph_root: GraphRoot, did: str, corpus: str) -> DocNode {
    d = DocNode(did=did, corpus=corpus);
    graph_root +>:HasDoc:+> d;
    print(f"add_document {did}");
    return d;
}

def add_term(doc: DocNode, tid: str, text: str) -> TermNode {
    t = TermNode(tid=tid, text=text);
    doc +>:Contains:+> t;
    print(f"add_term {tid}");
    return t;
}

def upsert_entries(dict_node: DictNode, entries: list[TermNode]) -> bool {
    # synchronous SQLite transaction semantics - fail before Promise
    for e in entries {
        if e.text == "FAIL" {
            print("upsert sync fail");
            raise Exception("dictionary settlement rejected");
        }
    }
    for e in entries {
        dict_node.store[e.tid] = e.text;
        print(f"upsert {e.tid}");
    }
    print("upsert settled");
    return True;
}

def buildIncremental(builder: LexiconBuilder, doc_id: str) -> LexiconBuildResult {
    doc: DocNode | None = find_doc(builder.graph_root, doc_id);
    if doc is None {
        print("buildIncremental unknown doc");
        res = LexiconBuildResult(doc_id=doc_id, entries={}, success=True);
        return res;
    }
    w = doc spawn BuildCollectWalker(claimed={}, collected=[]);
    entries: list[TermNode] = w.collected;
    # exactly one awaited settlement if entries exist
    if len(entries) > 0 {
        upsert_entries(builder.dict_node, entries);
        print("buildIncremental settled");
    } else {
        print("buildIncremental no entries");
    }
    out: dict[str, str] = {};
    for e in entries {
        out[e.tid] = e.text;
    }
    print(f"built {doc_id}");
    res2 = LexiconBuildResult(doc_id=doc_id, entries=out, success=True);
    return res2;
}

def backfill(builder: LexiconBuilder, corpus_id: str) -> LexiconBuildResult {
    w = builder.graph_root spawn BackfillCollectWalker(corpus_id=corpus_id, claimed={}, collected=[]);
    entries: list[TermNode] = w.collected;
    if len(entries) > 0 {
        upsert_entries(builder.dict_node, entries);
        print("backfill settled");
    } else {
        print("backfill no entries");
    }
    out: dict[str, str] = {};
    for e in entries {
        out[e.tid] = e.text;
    }
    print(f"backfilled {corpus_id}");
    res = LexiconBuildResult(doc_id=corpus_id, entries=out, success=True);
    return res;
}

def pipeline_index(builder: LexiconBuilder, doc_id: str) -> LexiconBuildResult {
    try {
        r = buildIncremental(builder, doc_id);
        print("pipeline success");
        return r;
    } except Exception as e {
        print(f"pipeline wrap {e}");
        raise Exception(f"DocumentMutationError: {e}");
    }
}

def run_job(builder: LexiconBuilder, doc_id: str) -> LexiconBuildResult {
    batch_open: bool = True;
    try {
        r2 = pipeline_index(builder, doc_id);
        if batch_open {
            print("commit batch");
            batch_open = False;
        }
        return r2;
    } except Exception as e {
        if batch_open {
            print("abandon batch");
            batch_open = False;
        }
        print(f"job failed {e}");
        raise e;
    }
}

with entry {
    gr2 = GraphRoot(name="demo");
    root ++> gr2;
    dn2 = DictNode(store={});
    gr2 ++> dn2;
    b2 = LexiconBuilder(graph_root=gr2, dict_node=dn2);
    root ++> b2;
    d0 = DocNode(did="demo_doc", corpus="c0");
    gr2 +>:HasDoc:+> d0;
    t0 = TermNode(tid="t0", text="hello");
    d0 +>:Contains:+> t0;
    w0 = gr2 spawn BackfillCollectWalker(corpus_id="c0", claimed={}, collected=[]);
    print("demo done");
}
