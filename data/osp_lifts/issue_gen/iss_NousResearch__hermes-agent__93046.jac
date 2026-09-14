# PROGRAM: iss_NousResearch__hermes-agent__93046.jac

node Project {
    has name: str;
    has primary_root: str;
    has primary_verified: bool = False;
}

node Board {
    has name: str;
    has default_workdir: str;
    has default_verified: bool = False;
}

node Card {
    has task_id: str;
    has workspace_path: str;
    has anchor_root: str;
    has workspace_suffix: str;
    has workspace_source: str = "project";
    has status: str = "ready";
    has branch: str;
    has explicit_override: bool = False;
    has events: list[str] = [];
}

edge ProjectBoard {}
edge BoardCard {}
edge DependsOn {}

walker CardCollector {
    has claimed: dict[str, bool] = {};
    has found: list[Card] = [];

    can collect_project with Project entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("scanning project workspace cards");
        for board in [here ->:ProjectBoard:->][?:Board] {
            visit :0: [board];
        }
    }

    can collect_board with Board entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        for card in [here ->:BoardCard:->][?:Card] {
            visit :0: [card];
        }
    }

    can collect_card with Card entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.found.append(here);
        for dependency in [here ->:DependsOn:->][?:Card] {
            visit :0: [dependency];
        }
    }
}

def make_project(name: str, primary_root: str,
                 primary_verified: bool = False) -> Project {
    return Project(name=name, primary_root=primary_root,
                   primary_verified=primary_verified);
}

def make_board(name: str, default_workdir: str,
               default_verified: bool = False) -> Board {
    return Board(name=name, default_workdir=default_workdir,
                 default_verified=default_verified);
}

def make_card(task_id: str, workspace_path: str, anchor_root: str,
              workspace_suffix: str, branch: str,
              workspace_source: str = "project") -> Card {
    return Card(task_id=task_id, workspace_path=workspace_path,
                anchor_root=anchor_root, workspace_suffix=workspace_suffix,
                branch=branch, workspace_source=workspace_source);
}

def link_board(project: Project, board: Board) -> None {
    project +>:ProjectBoard:+> board;
}

def add_card(board: Board, card: Card) -> None {
    board +>:BoardCard:+> card;
}

def link_dependency(card: Card, prerequisite: Card) -> None {
    card +>:DependsOn:+> prerequisite;
}

def set_card_state(card: Card, status: str) -> None {
    card.status = status;
}

def mark_override(card: Card, workspace_path: str) -> None {
    card.workspace_path = workspace_path;
    card.workspace_source = "explicit";
    card.explicit_override = True;
}

def set_primary(project: Project, primary_root: str,
                verified: bool) -> int {
    project.primary_root = primary_root;
    project.primary_verified = verified;
    return len(_collect_cards(project));
}

def set_default_workdir(board: Board, workdir: str,
                        verified: bool) -> None {
    board.default_workdir = workdir;
    board.default_verified = verified;
}

def _collect_cards(project: Project) -> list[Card] {
    w = project spawn CardCollector(claimed={});
    return w.found;
}

def rebind_workspaces(project: Project, from_root: str,
                      to_root: str, apply: bool = False) -> list[str] {
    ids: list[str] = [];
    cards = _collect_cards(project);
    if not project.primary_verified or project.primary_root != to_root {
        return ids;
    }
    for card in cards {
        eligible: bool = card.workspace_source == "project";
        eligible = eligible and not card.explicit_override;
        eligible = eligible and card.anchor_root == from_root;
        eligible = eligible and card.workspace_suffix != "";
        eligible = eligible and card.workspace_path ==
            from_root + card.workspace_suffix;
        eligible = eligible and card.status != "running";
        eligible = eligible and card.status != "claimed";
        collision: bool = False;
        for other in cards {
            if other.cid != card.cid and other.branch == card.branch {
                collision = True;
            }
        }
        if eligible and not collision {
            ids.append(card.task_id);
            if apply {
                card.workspace_path = to_root + card.workspace_suffix;
                card.anchor_root = to_root;
                card.events.append("workspace-rebind:" + from_root +
                                   "->" + to_root);
            }
        }
    }
    return ids;
}

def rebind_task(project: Project, task_id: str,
                to_root: str, apply: bool = False) -> bool {
    cards = _collect_cards(project);
    for card in cards {
        if card.task_id == task_id {
            ids = rebind_workspaces(project, card.anchor_root,
                                    to_root, apply);
            for changed in ids {
                if changed == task_id {
                    return True;
                }
            }
        }
    }
    return False;
}
