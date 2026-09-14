"""EffortlessMetrics/perl-lsp-swarm#12445"""

node Generation {
    has generation_id: str;
    has profile: str;
    has candidate: str;
    has selection: str;
    has current: bool = True;
}

node PacketMember {
    has issue: int;
    has kind: str;
    has generation_id: str;
    has profile: str;
    has candidate: str;
    has selection: str;
    has current: bool = True;
    has source_issue: int = 0;
    has state: str = "not-proven";
    has rows: list[str] = [];
}

node Rail {
    has name: str;
    has state: str = "not-proven";
}

edge Contains {}

walker Capture {
    has claimed: dict[str, bool] = {};
    has members: list[PacketMember] = [];
    has rails: list[Rail] = [];

    can step_generation with Generation entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print(here.generation_id);
        for member in [here ->:Contains:->][?:PacketMember] {
            visit :0: [member];
        }
    }

    can step_member with PacketMember entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.members.append(here);
        print(here.kind);
        for member in [here ->:Contains:->][?:PacketMember] {
            visit :0: [member];
        }
        for rail in [here ->:Contains:->][?:Rail] {
            visit :0: [rail];
        }
    }

    can step_rail with Rail entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        self.rails.append(here);
        print(here.name);
    }
}

def make_generation(
    generation_id: str,
    profile: str,
    candidate: str,
    selection: str,
    status_member: PacketMember,
    join_member: PacketMember,
    rail_member: PacketMember,
    rails: list[Rail] | None = None
) -> Generation {
    graph_root = Generation(
        generation_id=generation_id,
        profile=profile,
        candidate=candidate,
        selection=selection
    );
    graph_root +>:Contains:+> status_member;
    graph_root +>:Contains:+> join_member;
    graph_root +>:Contains:+> rail_member;
    join_member +>:Contains:+> status_member;
    rail_member +>:Contains:+> status_member;
    if rails != None {
        for rail in rails {
            rail_member +>:Contains:+> rail;
        }
    }
    return graph_root;
}

def capture_current(graph_root: Generation) -> list[PacketMember] {
    w = graph_root spawn Capture(claimed={});
    return w.members;
}

def identity_count(
    members: list[PacketMember],
    graph_root: Generation,
    issue_no: int,
    kind: str
) -> int {
    count: int = 0;
    for member in members {
        if member.issue == issue_no
            && member.kind == kind
            && member.generation_id == graph_root.generation_id
            && member.profile == graph_root.profile
            && member.candidate == graph_root.candidate
            && member.selection == graph_root.selection {
            count += 1;
        }
    }
    return count;
}

def current_member(
    members: list[PacketMember],
    graph_root: Generation,
    issue_no: int,
    kind: str
) -> PacketMember | None {
    found: PacketMember | None = None;
    for member in members {
        if member.issue == issue_no
            && member.kind == kind
            && member.generation_id == graph_root.generation_id
            && member.profile == graph_root.profile
            && member.candidate == graph_root.candidate
            && member.selection == graph_root.selection
            && member.current == True
            && graph_root.current == True {
            found = member;
        }
    }
    return found;
}

def has_row(member: PacketMember | None, row_name: str) -> bool {
    if member == None {
        return False;
    }
    for row in member.rows {
        if row == row_name {
            return True;
        }
    }
    return False;
}

def editor_intelligence(graph_root: Generation) -> dict[str, str] {
    members = capture_current(graph_root);
    result: dict[str, str] = {};
    result["canonical_facts"] = "unchanged";
    result["provider_behavior"] = "unchanged";
    result["edit_authorization"] = "unchanged";
    result["representative_project"] = "unchanged";
    result["installed_client"] = "unchanged";
    result["support"] = "unchanged";

    join_count = identity_count(members, graph_root, 12200, "editor_intelligence_join.v1");
    status_count = identity_count(members, graph_root, 12351, "compiler_profile_status.v1");
    join_member = current_member(members, graph_root, 12200, "editor_intelligence_join.v1");
    status_member = current_member(members, graph_root, 12351, "compiler_profile_status.v1");

    join_state: str = "unavailable";
    if join_count > 1 {
        join_state = "conflicting";
    } elif join_member != None {
        join_state = "current";
    }

    status_state: str = "unavailable";
    if status_count > 1 {
        status_state = "conflicting";
    } elif status_member != None {
        status_state = status_member.state;
    }

    source_ok: bool = False;
    if join_member != None {
        source_ok = join_member.source_issue == 12351;
    }
    join_ok: bool = join_count == 1
        && status_count == 1
        && join_member != None
        && status_member != None
        && source_ok
        && has_row(join_member, "compiler_substrate");

    result["join_state"] = join_state;
    result["compiler_profile_status"] = status_state;
    if join_ok {
        if status_state == "pass" {
            result["compiler_substrate"] = "available";
        } else {
            result["compiler_substrate"] = "blocked_" + status_state;
        }
    } else {
        result["compiler_substrate"] = "unavailable";
    }
    return result;
}

def product_health(graph_root: Generation) -> dict[str, str] {
    members = capture_current(graph_root);
    w = graph_root spawn Capture(claimed={});
    result: dict[str, str] = {};
    result["compiler_profile.v1"] = "unavailable";
    result["compiler_profile.v2"] = "unavailable";

    rail_count = identity_count(members, graph_root, 12201, "product_health_rail.v1");
    status_count = identity_count(members, graph_root, 12351, "compiler_profile_status.v1");
    rail_member = current_member(members, graph_root, 12201, "product_health_rail.v1");
    status_member = current_member(members, graph_root, 12351, "compiler_profile_status.v1");

    status_state: str = "unavailable";
    if status_count > 1 {
        status_state = "conflicting";
    } elif status_member != None {
        status_state = status_member.state;
    }

    source_ok: bool = False;
    if rail_member != None {
        source_ok = rail_member.source_issue == 12351;
    }
    packet_ok: bool = rail_count == 1 && rail_member != None && source_ok;

    if packet_ok {
        for rail in w.rails {
            if rail.name == "compiler_profile.v1" || rail.name == "compiler_profile.v2" {
                if status_state == "pass" {
                    result[rail.name] = rail.state;
                } else {
                    result[rail.name] = "blocked_" + status_state;
                }
            } else {
                result[rail.name] = rail.state;
            }
        }
    }
    return result;
}
