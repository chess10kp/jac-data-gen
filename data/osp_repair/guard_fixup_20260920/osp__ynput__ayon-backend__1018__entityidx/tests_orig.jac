test "canonical path and subtree flood" {
    ix = build_index(["project"]);
    add_folder(ix, "assets", "project", {"atlas": True});
    add_folder(ix, "shots", "project");
    add_folder(ix, "shot010", "shots", {"frame_start": 1001});
    assert canonical_path(ix, "shot010") == "project/shots/shot010";
    assert canonical_path(ix, "assets") == "project/assets";
    assert subtree_folders(ix, "project") == ["assets", "project", "shot010", "shots"];
}

test "unknown-id tolerance matches source" {
    ix = build_index(["only"]);
    assert canonical_path(ix, "ghost") == "ghost";
    assert subtree_folders(ix, "ghost") == ["ghost"];
    assert inherited_attribute(ix, "ghost", "level") is None;
    assert versions_in_subtree(ix, "ghost") == [];
}

test "inherited attribute nearest ancestor wins" {
    ix = build_index(["root", "mid"]);
    add_folder(ix, "mid", "root", {"level": 0});
    add_folder(ix, "leaf", "mid", {"level": 2});
    assert inherited_attribute(ix, "leaf", "level") == 2;
    assert inherited_attribute(ix, "mid", "level") == 0;
    try {
        add_folder(ix, "bad", "ghost");
        assert False;
    } except KeyError { assert True; }
}

test "cross-type chain query through three hops" {
    ix = build_index(["proj", "empty"]);
    attach_chain(ix, task="t_comp", folder="proj");
    attach_chain(ix, task="t_model", folder="empty");
    attach_chain(ix, product=("p_render", "t_comp"));
    attach_chain(ix, product=("p_cache", "t_model"));
    attach_chain(ix, version=("v001", "p_render"));
    attach_chain(ix, version=("v002", "p_render"));
    assert versions_in_subtree(ix, "proj") == ["v001", "v002"];
    assert versions_in_subtree(ix, "empty") == [];
    assert entities_of_type(ix, "task") == ["t_comp", "t_model"];
    assert entities_of_type(ix, "product") == ["p_cache", "p_render"];
    assert entities_of_type(ix, "version") == ["v001", "v002"];
    assert entities_of_type(ix, "folder", "empty") == ["empty"];
    assert entities_of_type(ix, "folder") == ["empty", "proj"];  # no root: all
}

test "attach_chain validates each hop" {
    ix = build_index(["p1"]);
    try {
        attach_chain(ix, task="t", folder="nowhere");
        assert False;
    } except KeyError { assert True; }
    attach_chain(ix, task="t", folder="p1");
    try {
        attach_chain(ix, product=("prod", "no_task"));
        assert False;
    } except KeyError { assert True; }
    attach_chain(ix, product=("prod", "t"));
    try {
        attach_chain(ix, version=("v", "no_prod"));
        assert False;
    } except KeyError { assert True; }
    attach_chain(ix, version=("v", "prod"));
    assert entities_of_type(ix, "version") == ["v"];
}

test "corrupt folder cycle terminates" {
    ix = build_index(["x", "y"]);
    xn = ix.resolve("x");
    yn = ix.resolve("y");
    xn +>:ChildFolder:+> yn;
    yn +>:ChildFolder:+> xn;
    assert len(subtree_folders(ix, "x")) == 2;
    w = xn spawn PathAscent(visited={});
    assert len(w.parts) == 2;   # stops on revisit
}