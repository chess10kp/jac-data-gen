import from main { Instances, Scene, SceneValidator }
test "composed scene reports child problems by child file" {
    parent = Scene(path="parent.tscn");
    child = Scene(path="child.tscn");

    root +>:Instances(instance_id="parent->child"):+> parent;
    parent +>:Instances(instance_id="parent->child"):+> child;

    validator = SceneValidator();
    root spawn validator;

    assert parent.valid == True, f"parent validity: {parent.valid}";
    assert child.valid == False, f"child validity: {child.valid}";
    assert "missing script: res://broken.gd" in child.problems,
        f"child problems: {child.problems}";
    assert "missing texture: res://missing.png" in child.problems,
        f"child problems: {child.problems}";
    assert len(parent.problems) == 0, f"parent problems: {parent.problems}";
}

test "scene cycles terminate with a structured diagnostic" {
    parent = Scene(path="parent.tscn");
    child = Scene(path="child.tscn");

    root +>:Instances(instance_id="root->parent"):+> parent;
    parent +>:Instances(instance_id="parent->child"):+> child;
    child +>:Instances(instance_id="child->parent-cycle"):+> parent;

    validator = SceneValidator();
    root spawn validator;

    assert validator.cycle_detected == True,
        f"cycle detected: {validator.cycle_detected}";
    assert parent.valid == False, f"parent validity: {parent.valid}";
    assert "cycle: already visited parent.tscn" in parent.problems,
        f"parent problems: {parent.problems}";
}

test "known-good composed scene remains valid" {
    good_parent = Scene(path="good_parent.tscn");
    good_child = Scene(path="good_child.tscn");

    root +>:Instances(instance_id="parent->child"):+> good_parent;
    good_parent +>:Instances(instance_id="parent->child"):+> good_child;

    validator = SceneValidator();
    root spawn validator;

    assert good_parent.valid == True,
        f"good parent validity: {good_parent.valid}";
    assert good_child.valid == True,
        f"good child validity: {good_child.valid}";
    assert len(good_parent.problems) == 0,
        f"good parent problems: {good_parent.problems}";
    assert len(good_child.problems) == 0,
        f"good child problems: {good_child.problems}";
}
