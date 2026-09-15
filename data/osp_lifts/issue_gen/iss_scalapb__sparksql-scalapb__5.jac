"""scalapb/sparksql-scalapb#5 — cycle-safe recursive proto struct-field expansion."""

node Message {
    has mid: str;
    has label: str;
}

node Field {
    has fid: str;
    has fname: str;
    has ftype: str;
    has ref_mid: str = "";
}

edge Contains {}
edge Refs {}

def add_field(msg: Message, fname: str, ftype: str, ref_mid: str) -> Field {
    fid = msg.mid + "." + fname;
    f = Field(fid=fid, fname=fname, ftype=ftype, ref_mid=ref_mid);
    msg +>:Contains:+> f;
    return f;
}

def link_ref(f: Field, target: Message) -> None {
    f +>:Refs:+> target;
}

def make_registry() -> object {
    reg: object = {};
    msgs: dict[str, Message] = {};
    person = Message(mid="Person", label="Person");
    dept = Message(mid="Department", label="Department");
    org = Message(mid="Org", label="Org");
    root ++> person;
    root ++> dept;
    root ++> org;
    pf_id = add_field(person, "id", "int32", "");
    pf_name = add_field(person, "name", "string", "");
    pf_mgr = add_field(person, "manager", "message", "Person");
    link_ref(pf_mgr, person);
    df_title = add_field(dept, "title", "string", "");
    df_head = add_field(dept, "head", "message", "Person");
    df_parent = add_field(dept, "parent", "message", "Department");
    link_ref(df_head, person);
    link_ref(df_parent, dept);
    of_name = add_field(org, "name", "string", "");
    of_a = add_field(org, "dept_a", "message", "Department");
    of_b = add_field(org, "dept_b", "message", "Department");
    link_ref(of_a, dept);
    link_ref(of_b, dept);
    msgs["Person"] = person;
    msgs["Department"] = dept;
    msgs["Org"] = org;
    reg["msgs"] = msgs;
    return reg;
}

def list_message_names(reg: object) -> list[str] {
    msgs = reg["msgs"] as dict[str, Message];
    names: list[str] = [];
    for k in msgs {
        names.append(k);
    }
    return sorted(names);
}

def top_level_fields(reg: object, message_id: str) -> list[str] {
    msgs = reg["msgs"] as dict[str, Message];
    if message_id not in msgs {
        return [];
    }
    msg = msgs[message_id];
    kids: list[Field] = [msg ->:Contains:->][?:Field];
    names: list[str] = [];
    for f in kids {
        names.append(f.fname);
    }
    return sorted(names);
}

walker ExpandStruct {
    has claimed: dict[str, bool] = {};
    has collected: list[str] = [];

    can step_msg with Message entry {
        if here.mid in self.claimed {
            skip;
        }
        self.claimed[here.mid] = True;
        kids: list[Field] = [here ->:Contains:->][?:Field];
        for f in kids {
            self.collected.append(f.fname);
            if f.ftype == "message" and f.ref_mid != "" {
                ref_msgs: list[Message] = [f ->:Refs:->][?:Message];
                if len(ref_msgs) > 0 {
                    visit :0: ref_msgs;
                }
            }
        }
        print("expand", here.mid, len(self.collected));
    }
}

def expand_struct_fields(reg: object, message_id: str) -> list[str] {
    msgs = reg["msgs"] as dict[str, Message];
    if message_id not in msgs {
        return [];
    }
    start = msgs[message_id];
    w = start spawn ExpandStruct(claimed={}, collected=[]);
    names: list[str] = [];
    for nm in w.collected {
        names.append(nm);
    }
    return sorted(names);
}

def struct_field_for(reg: object, message_id: str, field_name: str) -> dict {
    msgs = reg["msgs"] as dict[str, Message];
    if message_id not in msgs {
        return {};
    }
    msg = msgs[message_id];
    kids: list[Field] = [msg ->:Contains:->][?:Field];
    for f in kids {
        if f.fname == field_name {
            out: dict = {};
            out["name"] = f.fname;
            out["type"] = f.ftype;
            out["message"] = f.ref_mid;
            return out;
        }
    }
    return {};
}
