test "recompute union" {
    store = make_store();
    add_video(store, "parent", None, "container", {"en"});
    add_video(store, "child1", "parent", "variant", {"es"});
    add_video(store, "child2", "parent", "variant", {"fr"});
    assert recompute_available(store, "parent") == {"en", "es", "fr"};
}

test "create empty variant recomputes" {
    store = make_store();
    add_video(store, "p", None, "container", {"en"});
    vid = create_empty_parent_variant(store, "p");
    assert vid == "p::variant";
    assert available_languages(store, "p") == ["en"];
}

test "cleanup removes empty only" {
    store = make_store();
    add_video(store, "p", None, "container", {"en"});
    create_empty_parent_variant(store, "p");
    assert check_and_remove_empty_parent_variant(store, "p::variant") == True;
    assert not ("p::variant" in store.vids);
    add_video(store, "p2", None, "container", {"en"});
    add_video(store, "v", "p2", "variant", {"de"});
    assert check_and_remove_empty_parent_variant(store, "v") == False;
}

test "shared lookup restricts to container" {
    store = make_store();
    add_video(store, "leaf", None, "leaf", {"en"});
    add_video(store, "c", "leaf", "variant", {});
    assert _shared_parent_lookup(store, "c") == None;
    assert check_and_remove_empty_parent_variant(store, "c") == False;
}

test "diamond closure" {
    store = make_store();
    add_video(store, "root", None, "container", {});
    add_video(store, "a", "root", "variant", {"en"});
    add_video(store, "b", "root", "variant", {"es"});
    assert recompute_available(store, "root") == {"en", "es"};
}