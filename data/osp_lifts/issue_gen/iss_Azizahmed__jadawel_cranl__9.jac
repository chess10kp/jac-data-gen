node Field {
    has name: str;
    has protected: bool = False;
    has public_id: bool = False;
    has display_only: bool = False;
    has contract_known: bool = True;
    has supported: bool = True;
    has broken: bool = False;
    has kind: str = "value";
}

edge Depends {}

walker Trace {
    has claimed: dict[str, bool] = {};
    has protected: bool = False;
    has invalid: bool = False;
    has display_only: bool = False;
    has names: list[str] = [];

    can inspect with Field entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.names.append(here.name);
        print(here.name);

        if here.protected {
            self.protected = True;
        }
        if here.display_only {
            self.display_only = True;
        }
        if not here.contract_known {
            self.invalid = True;
        }
        if not here.supported {
            self.invalid = True;
        }
        if here.broken {
            self.invalid = True;
        }

        for dep in [here ->:Depends:->][?:Field] {
            visit :0: [dep];
        }
    }
}

def demo_fields() -> list[Field] {
    fields: list[Field] = [];
    secret: Field = Field(name="secret", protected=True);
    public_key: Field = Field(name="public_key", public_id=True, kind="identifier");
    left: Field = Field(name="left", kind="formula");
    right: Field = Field(name="right", kind="lookup");
    derived: Field = Field(name="derived", kind="rollup");
    label: Field = Field(name="label", display_only=True, kind="linked_label");

    left +>:Depends:+> secret;
    right +>:Depends:+> secret;
    derived +>:Depends:+> left;
    derived +>:Depends:+> right;
    label +>:Depends:+> derived;
    label +>:Depends:+> public_key;

    fields.append(secret);
    fields.append(public_key);
    fields.append(left);
    fields.append(right);
    fields.append(derived);
    fields.append(label);
    return fields;
}

def find_field(fields: list[Field], wanted: str) -> Field | None {
    for field in fields {
        if field.name == wanted {
            return field;
        }
    }
    return None;
}

def lineage(start: Field) -> list[str] {
    w = start spawn Trace(claimed={});
    return w.names;
}

def mask_leaf(field: Field) -> str {
    w = field spawn Trace(claimed={});
    if w.invalid {
        return "MASKED";
    }
    if w.protected {
        if not field.public_id {
            return "MASKED";
        }
    }
    return field.name;
}

def query_allowed(outputs: list[Field], operation: str) -> bool {
    if len(outputs) == 0 {
        return True;
    }

    blocked: list[str] = [
        "search", "filter", "sort", "group", "membership", "count"
    ];
    shape_sensitive: bool = False;
    for name in blocked {
        if operation == name {
            shape_sensitive = True;
        }
    }

    known_operation: bool = operation == "read" or operation == "display";
    for name in blocked {
        if operation == name {
            known_operation = True;
        }
    }
    if operation == "mutate" {
        known_operation = True;
    }
    if not known_operation {
        return False;
    }

    for field in outputs {
        w = field spawn Trace(claimed={});
        if w.invalid {
            return False;
        }
        if w.protected {
            if shape_sensitive {
                return False;
            }
        }
        if w.display_only {
            if operation == "mutate" {
                return False;
            }
        }
    }
    return True;
}
