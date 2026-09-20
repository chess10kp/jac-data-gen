test "deep delete removes every level and keeps join integrity" {
    cat = build_catalog(["products", "hardware", "software"], [("products", "hardware"), ("products", "software")]);
    add_category(cat, "laptops", "hardware", 0);
    add_category(cat, "gaming", "laptops", 0);
    add_category(cat, "rtx", "gaming", 0);
    attach_content(cat, "sku-1", "rtx");
    attach_content(cat, "sku-1", "software");
    attach_content(cat, "sku-2", "gaming");
    assert contents_in_subtree(cat, "gaming") == ["sku-1", "sku-2"];
    rep = delete_category_deep(cat, "laptops");
    assert rep == (3, [1, 1, 1]), rep;
    assert orphaned_categories(cat) == [];
    # cross-listed link outside the doomed set survives
    assert contents_in_subtree(cat, "products") == ["sku-1"];
}

test "sibling order observable" {
    cat = build_catalog(["root"], []);
    add_category(cat, "beta", "root", 2);
    add_category(cat, "alpha", "root", 1);
    add_category(cat, "gamma", "root", 3);
    assert children_ordered(cat, "root") == ["alpha", "beta", "gamma"];
    assert children_ordered(cat, "ghost") == [];  # source tolerance
}

test "level structure pinned on wider tree" {
    cat = build_catalog(["r", "a", "b", "a1", "a2", "a1x"], [("r", "a"), ("r", "b"), ("a", "a1"), ("a", "a2"), ("a1", "a1x")]);
    lv = subtree_levels(cat, "r");
    lens: list[int] = [];
    for l in lv {
        lens.append(len(l));
    }
    assert lens == [1, 2, 2, 1];
    rep = delete_category_deep(cat, "a");
    assert rep == (4, [1, 2, 1]);
    assert orphaned_categories(cat) == [];
    assert children_ordered(cat, "r") == ["b"];
}

test "adversarial diamond terminates once-only" {
    cat = build_catalog(["top", "l", "rr"], []);
    tn = cat.resolve("top");
    ln = cat.resolve("l");
    rn = cat.resolve("rr");
    bot = CategoryNode(name="bot");
    root ++> bot;
    cat.cats["bot"] = bot;
    ln +>:ChildCategory:+> bot;
    rn +>:ChildCategory:+> bot;
    tn +>:ChildCategory:+> ln;
    tn +>:ChildCategory:+> rn;
    rep = delete_category_deep(cat, "top");
    assert rep == (4, [1, 2, 1]), rep;
    assert orphaned_categories(cat) == [];
}