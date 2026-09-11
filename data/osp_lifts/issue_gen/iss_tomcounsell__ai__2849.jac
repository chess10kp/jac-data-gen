node IssueNode { has issue_number: int; has title: str; }
node TaskNode { has task_id: str; has issue_number: int; }
node SessionNode { has session_id: str; has issue_url: str; }
node StageNode { has name: str; has kind: str; }

edge Depends {}
edge Handles {}
edge Refers {}

walker ReachWalker {
    has claimed: dict[str, bool] = {};
    has found: list[str] = [];
    can step with StageNode entry {
        if here.name in self.claimed { skip; }
        self.claimed[here.name] = True;
        self.found.append(here.name);
        print(here.name);
        successors: list[StageNode] = [here ->:Depends:->][?:StageNode];
        if len(successors) > 0 {
            visit :0: successors;
        } else {
            disengage;
        }
    }
}

walker LineageWalker {
    has claimed: dict[str, bool] = {};
    has issues: list[int] = [];
    can step_session with SessionNode entry {
        if here.session_id in self.claimed { skip; }
        self.claimed[here.session_id] = True;
        print(here.session_id);
        kids: list[TaskNode] = [here ->:Handles:->][?:TaskNode];
        if len(kids) > 0 {
            visit kids;
        } else {
            disengage;
        }
    }
    can step_task with TaskNode entry {
        if here.task_id in self.claimed { skip; }
        self.claimed[here.task_id] = True;
        print(here.task_id);
        self.issues.append(here.issue_number);
        disengage;
    }
}

def extract_issue_number(url: str) -> str {
    cur: str = "";
    best: str = "";
    for ch in url {
        if ch == "0" or ch == "1" or ch == "2" or ch == "3" or ch == "4" or ch == "5" or ch == "6" or ch == "7" or ch == "8" or ch == "9" {
            cur = cur + ch;
        } else {
            if len(cur) > 0 {
                best = cur;
            }
            cur = "";
        }
    }
    if len(cur) > 0 {
        best = cur;
    }
    return best;
}

def create_session(session_id: str, issue_url: str) -> SessionNode {
    nd = SessionNode(session_id=session_id, issue_url=issue_url);
    root ++> nd;
    return nd;
}
def create_issue(issue_number: int, title: str) -> IssueNode {
    nd = IssueNode(issue_number=issue_number, title=title);
    root ++> nd;
    return nd;
}
def create_task(task_id: str, issue_number: int) -> TaskNode {
    nd = TaskNode(task_id=task_id, issue_number=issue_number);
    root ++> nd;
    return nd;
}
def create_stage(name: str, kind: str) -> StageNode {
    nd = StageNode(name=name, kind=kind);
    root ++> nd;
    return nd;
}
def route_task(session: SessionNode, task: TaskNode) {
    session +>:Handles:+> task;
}
def add_dependency(a: StageNode, b: StageNode) {
    a +>:Depends:+> b;
}
def link_stage_issue(stage: StageNode, issue: IssueNode) {
    stage +>:Refers:+> issue;
}
def get_stale_issue_number(session: SessionNode) -> str {
    if len(session.issue_url) > 0 {
        return extract_issue_number(session.issue_url);
    }
    return "";
}
def get_effective_issue_number(session: SessionNode, task: TaskNode | None) -> str {
    if task is not None {
        return str(task.issue_number);
    }
    if len(session.issue_url) > 0 {
        return extract_issue_number(session.issue_url);
    }
    return "";
}
def get_reachable_stages(start: StageNode) -> list[str] {
    w = start spawn ReachWalker(claimed={}, found=[]);
    return w.found;
}
def get_session_task_issues(session: SessionNode) -> list[int] {
    w = session spawn LineageWalker(claimed={}, issues=[]);
    return w.issues;
}
def has_path(a: StageNode, b: StageNode) -> bool {
    reached: list[str] = get_reachable_stages(a);
    for n in reached {
        if n == b.name { return True; }
    }
    return False;
}

with entry {
    s = SessionNode(session_id="demo", issue_url="https://github.com/org/repo/issues/2734");
    root ++> s;
    w = s spawn LineageWalker(claimed={}, issues=[]);
    print("demo entry done");
}
