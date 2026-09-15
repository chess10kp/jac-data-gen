"""Prerequisite mutations with cycle rejection — safwauniversity/SUR#71."""

node Course {
    has cid: str;
    has name: str;
}

edge Prereq {}

node Catalog {
    has by_id: dict[str, Course] = {};
}

walker PrereqClosure {
    has target: str;
    has claimed: dict[str, bool] = {};
    has hit: bool = False;

    can step with Course entry {
        if here.cid in self.claimed { skip; }
        self.claimed[here.cid] = True;
        print("closure ", here.cid);
        if here.cid == self.target {
            self.hit = True;
            disengage;
        }
        kids: list[Course] = [];
        for p in [here <-:Prereq:<-][?:Course] {
            kids.append(p);
        }
        if len(kids) > 0 {
            visit :0: kids;
        } else {
            disengage;
        }
    }
}

def make_catalog -> Catalog {
    cat = Catalog();
    root ++> cat;
    return cat;
}

def add_course(cat: Catalog, cid: str, name: str) -> Course {
    nd = Course(cid=cid, name=name);
    cat.by_id[cid] = nd;
    cat ++> nd;
    return nd;
}

def has_prereq_link(prereq: Course, course: Course) -> bool {
    for n in [prereq ->:Prereq:->][?:Course] {
        if n.cid == course.cid {
            return True;
        }
    }
    return False;
}

def prereq_closure_hit(course: Course, target: str) -> bool {
    w = course spawn PrereqClosure(target=target, claimed={});
    return w.hit;
}

def admin_add_prerequisite(cat: Catalog, course_id: str, prereq_id: str) -> dict[str, any] {
    if course_id not in cat.by_id {
        return {"ok": False, "error": "missing_course"};
    }
    if prereq_id not in cat.by_id {
        return {"ok": False, "error": "missing_prereq"};
    }
    if course_id == prereq_id {
        return {"ok": False, "error": "self_prereq"};
    }
    course = cat.by_id[course_id];
    prereq = cat.by_id[prereq_id];
    if has_prereq_link(prereq, course) {
        return {"ok": True};
    }
    if prereq_closure_hit(course, prereq_id) {
        return {"ok": False, "conflict": prereq_id};
    }
    prereq +>:Prereq:+> course;
    return {"ok": True};
}

def admin_remove_prerequisite(cat: Catalog, course_id: str, prereq_id: str) -> dict[str, any] {
    if course_id not in cat.by_id {
        return {"ok": False, "error": "missing_course"};
    }
    if prereq_id not in cat.by_id {
        return {"ok": False, "error": "missing_prereq"};
    }
    course = cat.by_id[course_id];
    prereq = cat.by_id[prereq_id];
    if not has_prereq_link(prereq, course) {
        return {"ok": False, "error": "no_edge"};
    }
    prereq -:Prereq:- course;
    return {"ok": True};
}

with entry {
    cat = make_catalog();
    add_course(cat, "A", "Alpha");
    add_course(cat, "B", "Beta");
    r = admin_add_prerequisite(cat, "A", "B");
    print("demo add ", r);
    a = cat.by_id["A"];
    root spawn PrereqClosure(target="B", claimed={}, visit=[a]);
}

test "add_prereq_ok" {
    cat = make_catalog();
    add_course(cat, "A", "Alpha");
    add_course(cat, "B", "Beta");
    r = admin_add_prerequisite(cat, "A", "B");
    assert (r["ok"] == True);;
    course_a = cat.by_id["A"];
    course_b = cat.by_id["B"];
    assert (has_prereq_link(course_b, course_a) == True);;
}

test "self_prereq_rejected" {
    cat = make_catalog();
    add_course(cat, "A", "Alpha");
    r = admin_add_prerequisite(cat, "A", "A");
    assert (r["ok"] == False);;
    assert (r["error"] == "self_prereq");;
}

test "cycle_rejected_names_conflict" {
    cat = make_catalog();
    add_course(cat, "A", "Alpha");
    add_course(cat, "B", "Beta");
    admin_add_prerequisite(cat, "A", "B");
    r = admin_add_prerequisite(cat, "B", "A");
    assert (r["ok"] == False);;
    assert (r["conflict"] == "A");;
}

test "add_idempotent" {
    cat = make_catalog();
    add_course(cat, "A", "Alpha");
    add_course(cat, "B", "Beta");
    admin_add_prerequisite(cat, "A", "B");
    r = admin_add_prerequisite(cat, "A", "B");
    assert (r["ok"] == True);;
}

test "remove_ok" {
    cat = make_catalog();
    add_course(cat, "A", "Alpha");
    add_course(cat, "B", "Beta");
    admin_add_prerequisite(cat, "A", "B");
    r = admin_remove_prerequisite(cat, "A", "B");
    assert (r["ok"] == True);;
    course_a = cat.by_id["A"];
    course_b = cat.by_id["B"];
    assert (has_prereq_link(course_b, course_a) == False);;
}

test "remove_no_edge" {
    cat = make_catalog();
    add_course(cat, "A", "Alpha");
    add_course(cat, "B", "Beta");
    r = admin_remove_prerequisite(cat, "A", "B");
    assert (r["ok"] == False);;
    assert (r["error"] == "no_edge");;
}
