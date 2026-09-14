"""Neftedollar/FsLangMCP#158: extract-member impact analysis."""

node Scope {
    has name: str;
}

node Member {
    has name: str;
    has symbol: str;
    has kind: str;
    has position: int = 0;
    has recursive: bool = false;
    has locals: list[str] = [];
    has parameters: list[str] = [];
}

node State {
    has name: str;
    has category: str;
}

edge Contains {}
edge Captures {}
edge Calls {}

walker ImpactWalker {
    has selected: str;
    has all_members: bool = false;
    has claimed: dict[str, bool] = {};
    has captured: list[str] = [];
    has locals_found: list[str] = [];
    has parameters_found: list[str] = [];
    has called: list[str] = [];
    has edges: list[str] = [];
    has cycles: list[str] = [];
    has forward: list[str] = [];
    has called_seen: dict[str, bool] = {};
    has edge_seen: dict[str, bool] = {};
    has cycle_seen: dict[str, bool] = {};

    can select_scope with Scope entry {
        if self.all_members {
            for member_node in [here ->:Contains:->][?:Member] {
                visit :0: [member_node];
            }
        } else {
            exact_count: int = 0;
            name_count: int = 0;
            for member_node in [here ->:Contains:->][?:Member] {
                if member_node.symbol == self.selected {
                    exact_count += 1;
                }
                if member_node.name == self.selected {
                    name_count += 1;
                }
            }
            for member_node in [here ->:Contains:->][?:Member] {
                if exact_count == 1 && member_node.symbol == self.selected {
                    visit :0: [member_node];
                } elif exact_count == 0 && name_count == 1 &&
                    member_node.name == self.selected {
                    visit :0: [member_node];
                }
            }
        }
        print("impact-scope:" + here.name);
    }

    can inspect_member with Member entry {
        if here.symbol in self.claimed {
            skip;
        }
        self.claimed[here.symbol] = true;

        for state_node in [here ->:Captures:->][?:State] {
            if state_node.category == "field" ||
                state_node.category == "property" ||
                state_node.category == "constructor" {
                self.captured.append(here.symbol + ":" + state_node.name);
            }
        }
        for local_name in here.locals {
            self.locals_found.append(here.symbol + ":" + local_name);
        }
        for parameter_name in here.parameters {
            self.parameters_found.append(here.symbol + ":" + parameter_name);
        }
        if here.recursive && here.symbol not in self.cycle_seen {
            self.cycles.append("cycle:" + here.symbol);
            self.cycle_seen[here.symbol] = true;
        }
        if here.kind == "helper" &&
            len([here ->:Captures:->][?:State]) == 0 &&
            !here.recursive {
            self.called.append("pure:" + here.symbol);
        }

        for callee in [here ->:Calls:->][?:Member] {
            edge_name: str = here.symbol + "->" + callee.symbol;
            if callee.symbol not in self.called_seen {
                self.called.append(callee.symbol);
                self.called_seen[callee.symbol] = true;
            }
            if edge_name not in self.edge_seen {
                self.edges.append(edge_name);
                self.edge_seen[edge_name] = true;
            }
            if callee.position > here.position {
                self.forward.append(edge_name);
            }
            visit :0: [callee];
        }
        print("impact-member:" + here.symbol);
    }
}

walker EdgeWalker {
    has claimed: dict[str, bool] = {};
    has edges: list[str] = [];
    has forward: list[str] = [];
    has edge_seen: dict[str, bool] = {};

    can collect_scope with Scope entry {
        for member_node in [here ->:Contains:->][?:Member] {
            visit :0: [member_node];
        }
        print("edges-scope:" + here.name);
    }

    can collect_member with Member entry {
        if here.symbol in self.claimed {
            skip;
        }
        self.claimed[here.symbol] = true;
        for callee in [here ->:Calls:->][?:Member] {
            edge_name: str = here.symbol + "->" + callee.symbol;
            if edge_name not in self.edge_seen {
                self.edges.append(edge_name);
                self.edge_seen[edge_name] = true;
            }
            if callee.position > here.position {
                self.forward.append(edge_name);
            }
        }
        print("edge-member:" + here.symbol);
    }
}

def new_scope(name: str) -> Scope {
    return Scope(name=name);
}

def add_member(scope: Scope, symbol: str, kind: str,
               position: int = 0, recursive: bool = false,
               display_name: str | None = None) -> Member {
    member_name: str = symbol;
    if display_name != None {
        member_name = display_name;
    }
    member_node = Member(name=member_name, symbol=symbol, kind=kind,
                         position=position, recursive=recursive);
    scope ++> member_node;
    return member_node;
}

def add_capture(member_node: Member, name: str, category: str) -> State {
    state_node = State(name=name, category=category);
    member_node +>:Captures:+> state_node;
    return state_node;
}

def add_local(member_node: Member, name: str) -> None {
    member_node.locals.append(name);
}

def add_parameter(member_node: Member, name: str) -> None {
    member_node.parameters.append(name);
}

def add_call(caller: Member, callee: Member) -> None {
    caller +>:Calls:+> callee;
    if caller.symbol == callee.symbol {
        caller.recursive = true;
    }
}

def extract_impact(scope: Scope, selection: str) -> dict[str, list[str]] {
    w = scope spawn ImpactWalker(selected=selection,
                                 all_members=selection == scope.name,
                                 claimed={});
    ew = scope spawn EdgeWalker(claimed={});
    result: dict[str, list[str]] = {};
    result["captured"] = sorted(w.captured);
    result["locals"] = sorted(w.locals_found);
    result["parameters"] = sorted(w.parameters_found);
    result["called"] = sorted(w.called);
    result["edges"] = sorted(ew.edges);
    result["cycles"] = sorted(w.cycles);
    result["forward"] = sorted(ew.forward);
    result["pure"] = sorted(w.called);
    return result;
}

test "diamond revisit" {
    s = new_scope("T");
    a = add_member(s, "A", "member", 1);
    b = add_member(s, "B", "member", 2);
    c = add_member(s, "C", "member", 3);
    d = add_member(s, "D", "helper", 4);
    add_call(a, b);
    add_call(a, c);
    add_call(b, d);
    add_call(c, d);
    impact = extract_impact(s, "A");
    assert (impact["called"] == ["B", "C", "D", "pure:D"]);
    assert (len(impact["cycles"]) == 0);
    assert (impact["edges"] == ["A->B", "A->C", "B->D", "C->D"]);
}

test "unknown selection is tolerated" {
    s = new_scope("T");
    a = add_member(s, "A", "member", 1);
    b = add_member(s, "B", "member", 2);
    add_call(a, b);
    impact = extract_impact(s, "missing");
    assert (len(impact["captured"]) == 0);
    assert (len(impact["called"]) == 0);
    assert (impact["edges"] == ["A->B"]);
}

test "state locals parameters and forward risk stay separate" {
    s = new_scope("T");
    m = add_member(s, "M", "member", 1);
    h = add_member(s, "H", "helper", 4);
    add_capture(m, "balance", "field");
    add_capture(m, "ctor_limit", "constructor");
    add_local(m, "temporary");
    add_parameter(m, "account");
    add_call(m, h);
    impact = extract_impact(s, "M");
    assert (impact["captured"] == ["M:balance", "M:ctor_limit"]);
    assert (impact["locals"] == ["M:temporary"]);
    assert (impact["parameters"] == ["M:account"]);
    assert (impact["forward"] == ["M->H"]);
    assert ("pure:H" in impact["pure"]);
}

test "recursive and overloaded semantic members" {
    s = new_scope("T");
    loop = add_member(s, "loop#unit", "static", 1, true, "loop");
    parse_int = add_member(s, "parse#int", "extension", 2, false, "parse");
    parse_text = add_member(s, "parse#text", "extension", 3, false, "parse");
    add_call(loop, loop);
    add_call(loop, parse_text);
    impact = extract_impact(s, "loop#unit");
    assert ("cycle:loop#unit" in impact["cycles"]);
    assert ("parse#text" in impact["called"]);
    assert ("parse#int" not in impact["called"]);
}
