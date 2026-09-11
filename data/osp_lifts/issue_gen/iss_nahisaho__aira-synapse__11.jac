# nahisaho/aira-synapse#11 - await Stage V dictionary persistence before indexing success
node EntryNode { has term: str; has doc_id: str = ""; }
node BuilderNode { has corpus_id: str; has state: str = "not_started"; has last_doc: str = ""; }
node DictionaryNode { has call_count: int = 0; has should_fail: bool = False; has entries: list[str] = []; }
node PipelineNode { has batch_open: bool = True; has last_error: str = ""; }
node JobNode { has job_id: str; has status: str = "pending"; has batch_abandoned: bool = False; }
edge HasEntry {}
edge UsesDict {}
edge PipelineLink {}

walker CollectEntries {
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];
    can collect_b with BuilderNode entry {
        if here.corpus_id in self.claimed { skip; }
        self.claimed[here.corpus_id] = True;
        print(here.corpus_id);
        for kid in [here ->:HasEntry:->][?:EntryNode] { visit :0: [kid]; }
    }
    can collect_e with EntryNode entry {
        if here.term in self.claimed { skip; }
        self.claimed[here.term] = True;
        self.collected.append(here.term);
        print(here.term);
    }
}
walker ReachWalk {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    can r_b with BuilderNode entry {
        if here.corpus_id in self.claimed { skip; }
        self.claimed[here.corpus_id] = True;
        print(here.corpus_id);
        for nxt in [here ->:HasEntry:->][?:EntryNode] { visit :0: [nxt]; }
    }
    can r_e with EntryNode entry {
        if here.term in self.claimed { skip; }
        self.claimed[here.term] = True;
        self.order.append(here.term);
        print(here.term);
    }
}
def makeBuilder(corpus_id: str) -> BuilderNode { b = BuilderNode(corpus_id=corpus_id); return b; }
def makeDictionary(should_fail: bool) -> DictionaryNode { d = DictionaryNode(should_fail=should_fail); return d; }
def dictionaryUpsert(dict_node: DictionaryNode, terms: list[str]) -> bool {
    dict_node.call_count = dict_node.call_count + 1;
    if dict_node.should_fail { print("dict_fail"); return False; }
    for tt in terms { dict_node.entries.append(tt); }
    print("dict_ok");
    return True;
}
def buildIncremental(builder: BuilderNode, dict_node: DictionaryNode, doc_id: str, terms: list[str]) -> dict[str, str] {
    builder.state = "local_transaction_running";
    builder.last_doc = doc_id;
    for t in terms { nd = EntryNode(term=t, doc_id=doc_id); builder +>:HasEntry:+> nd; }
    builder.state = "dictionary_settlement_pending";
    ok: bool = dictionaryUpsert(dict_node, terms);
    if ok == False {
        builder.state = "failed";
        builder.state = "rejected";
        print("settlement_rejected");
        res_fail: dict[str, str] = {};
        res_fail["doc_id"] = doc_id;
        res_fail["status"] = "rejected";
        res_fail["error"] = "dictionary settlement rejected";
        return res_fail;
    }
    builder.state = "settled";
    builder.state = "returned";
    res: dict[str, str] = {};
    res["doc_id"] = doc_id;
    res["status"] = "settled";
    res["corpus"] = builder.corpus_id;
    print(res["status"]);
    return res;
}
def backfill(builder: BuilderNode, dict_node: DictionaryNode, doc_id: str, terms: list[str]) -> dict[str, str] { return buildIncremental(builder, dict_node, doc_id, terms); }
def indexDocument(pipeline: PipelineNode, builder: BuilderNode, dict_node: DictionaryNode, doc_id: str, terms: list[str]) -> dict[str, str] {
    res_inner: dict[str, str] = buildIncremental(builder, dict_node, doc_id, terms);
    if res_inner["status"] == "rejected" {
        pipeline.last_error = res_inner["error"];
        pipeline.batch_open = False;
        wrapped: dict[str, str] = {};
        wrapped["doc_id"] = doc_id;
        wrapped["status"] = "DocumentMutationError";
        wrapped["cause"] = res_inner["error"];
        print(wrapped["status"]);
        return wrapped;
    }
    print(res_inner["status"]);
    return res_inner;
}
def runJob(job_node: JobNode, pipeline: PipelineNode, builder: BuilderNode, dict_node: DictionaryNode, doc_id: str, terms: list[str]) -> dict[str, str] {
    job_node.status = "running";
    res: dict[str, str] = indexDocument(pipeline, builder, dict_node, doc_id, terms);
    if res["status"] == "DocumentMutationError" {
        job_node.status = "failed";
        job_node.batch_abandoned = True;
        pipeline.batch_open = False;
        print(job_node.status);
        return res;
    }
    job_node.status = "completed";
    pipeline.batch_open = False;
    print(job_node.status);
    return res;
}
def getReachableTerms(builder: BuilderNode) -> list[str] {
    w = builder spawn CollectEntries(claimed={});
    print(w.collected);
    out: list[str] = sorted(w.collected);
    return out;
}
with entry {
    b = BuilderNode(corpus_id="demo");
    d = DictionaryNode();
    p = PipelineNode();
    j = JobNode(job_id="j1");
    root ++> b;
    root ++> d;
    root ++> p;
    root ++> j;
    b +>:UsesDict:+> d;
    w = b spawn CollectEntries(claimed={});
    print(w.collected);
    w2 = b spawn ReachWalk(claimed={});
    print(w2.order);
    rw = root spawn CollectEntries(claimed={});
    print(rw.collected);
}
