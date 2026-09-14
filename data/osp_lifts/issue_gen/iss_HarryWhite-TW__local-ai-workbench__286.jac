node ReadbackRequest {
    has request_id: str;
    has repo: str;
    has issue: int;
    has parent_comment: str;
    has branch: str;
    has base_head: str;
    has fingerprint: str;
    has allowed: list[str];
    has manifest: dict[str, str];
}
node EvidenceFile {
    has path: str;
    has snapshot: str;
    has digest: str;
    has binary: bool = False;
    has secret_like: bool = False;
}
edge Bound {}
edge Related {}

walker ReadbackAudit {
    has claimed: dict[str, bool] = {};
    has valid: bool = True;
    has paths: list[str] = [];
    has snapshots: list[str] = [];
    has target: str = "";
    has found: bool = False;
    has found_text: str = "";

    can inspect_request with ReadbackRequest entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.request_id == "" { self.valid = False; }
        if here.repo == "" { self.valid = False; }
        if here.parent_comment == "" { self.valid = False; }
        print("readback audit " + here.request_id);
        kids: list[EvidenceFile] = [here ->:Bound:->][?:EvidenceFile];
        visit :0: [kids];
    }

    can inspect_file with EvidenceFile entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        if here.path not in self.allowed { self.valid = False; }
        if here.path in self.manifest {
            if self.manifest[here.path] != here.digest { self.valid = False; }
        } else {
            self.valid = False;
        }
        if here.binary { self.valid = False; }
        if here.secret_like { self.valid = False; }
        self.paths.append(here.path);
        self.snapshots.append(here.path + "\n" + here.snapshot);
        if here.path == self.target {
            self.found = True;
            self.found_text = here.snapshot;
        }
        kids: list[EvidenceFile] = [here ->:Related:->][?:EvidenceFile];
        visit :0: [kids];
    }
}

def make_request(request_id: str, repo: str, issue: int, parent_comment: str,
    branch: str, base_head: str, fingerprint: str, allowed: list[str],
    manifest: dict[str, str]) -> ReadbackRequest {
    return ReadbackRequest(request_id=request_id, repo=repo, issue=issue,
        parent_comment=parent_comment, branch=branch, base_head=base_head,
        fingerprint=fingerprint, allowed=allowed, manifest=manifest);
}

def make_evidence(path: str, snapshot: str, digest: str,
    binary: bool = False, secret_like: bool = False) -> EvidenceFile {
    return EvidenceFile(path=path, snapshot=snapshot, digest=digest,
        binary=binary, secret_like=secret_like);
}

def bind_evidence(req: ReadbackRequest, file: EvidenceFile) -> bool {
    req +>:Bound:+> file;
    return True;
}

def link_evidence(left: EvidenceFile, right: EvidenceFile) -> bool {
    left +>:Related:+> right;
    return True;
}

def verify_candidate(req: ReadbackRequest, branch: str, base_head: str,
    fingerprint: str) -> bool {
    if branch != req.branch { return False; }
    if base_head != req.base_head { return False; }
    if fingerprint != req.fingerprint { return False; }
    w = req spawn ReadbackAudit();
    if sorted(w.paths) != sorted(req.allowed) { return False; }
    return w.valid;
}

def exact_readback(req: ReadbackRequest, branch: str, base_head: str,
    fingerprint: str) -> list[str] {
    if verify_candidate(req, branch, base_head, fingerprint) == False {
        return [];
    }
    w = req spawn ReadbackAudit();
    return sorted(w.snapshots);
}

def snapshot_for(req: ReadbackRequest, path: str) -> str {
    w = req spawn ReadbackAudit(target=path);
    return w.found_text;
}
