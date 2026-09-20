test "resolve root and lineage on acyclic profile tree" {
    h = new_hierarchy();
    register_kind(h, "CoreGenericProfile");
    register_kind(h, "AristaGenericProfile", "CoreGenericProfile");
    register_kind(h, "AristaPortProfile", "AristaGenericProfile");
    assert resolve_root(h, "AristaPortProfile") == "CoreGenericProfile";
    assert lineage(h, "AristaPortProfile") == ["AristaGenericProfile", "CoreGenericProfile"];
    assert lineage(h, "CoreGenericProfile") == [];
    assert children_of(h, "AristaGenericProfile") == ["AristaPortProfile"];
    assert resolve_root(h, "AristaGenericProfile") == "CoreGenericProfile";
}

test "self-parent corruption raises SchemaCycleError" {
    h = new_hierarchy();
    register_kind(h, "AristaPortProfile");
    k = _find_kind(h, "AristaPortProfile");
    k +>:Extends:+> k;
    raised = False;
    try {
        resolve_root(h, "AristaPortProfile");
    } except SchemaCycleError {
        raised = True;
    }
    assert raised;
    raised = False;
    try {
        lineage(h, "AristaPortProfile");
    } except SchemaCycleError {
        raised = True;
    }
    assert raised;
}

test "multi-hop loop raises SchemaCycleError" {
    h = new_hierarchy();
    register_kind(h, "a");
    register_kind(h, "b", "a");
    register_kind(h, "c", "b");
    a = _find_kind(h, "a");
    c = _find_kind(h, "c");
    a del <-:Extends:<- c;
    c +>:Extends:+> a;
    raised = False;
    try {
        resolve_root(h, "c");
    } except SchemaCycleError {
        raised = True;
    }
    assert raised;
}