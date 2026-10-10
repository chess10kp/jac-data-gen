import uuid;
import from students { Student, add_student, retrieve_students, retrieve_student, update_student_data, delete_student }

def add(name: str, course: str, year: int, gpa: float) -> dict[str, any] {
    r = (root spawn add_student(fullname=name, email=name.lower() + "@school.com",
                                course_of_study=course, year=year, gpa=gpa)).reports[0];
    return dict(r);
}

def all_students -> list[dict[str, any]] {
    return list((root spawn retrieve_students()).reports[0]);
}

test "add student returns the stored record with an id" {
    tag = uuid.uuid4().hex[:8];
    before = len(all_students());
    s = add("ann" + tag, "Water resources engineering", 4, 3.76);
    assert len(str(s["id"])) > 0;
    assert s["fullname"] == "ann" + tag and s["email"] == "ann" + tag + "@school.com";
    assert s["course_of_study"] == "Water resources engineering";
    assert s["year"] == 4 and abs(s["gpa"] - 3.76) < 1e-9;
    assert len(all_students()) == before + 1;
    assert len([n for n in [root -->[?:Student]] if n.fullname == "ann" + tag]) == 1;
}

test "invalid email is rejected and nothing stored" {
    tag = uuid.uuid4().hex[:8];
    before = len(all_students());
    r = (root spawn add_student(fullname="bad" + tag, email="not-an-email", course_of_study="x", year=1, gpa=1.0)).reports[0];
    assert "error" in dict(r);
    assert len(all_students()) == before;
}

test "retrieve one by id, missing id gives None" {
    tag = uuid.uuid4().hex[:8];
    s = add("bob" + tag, "CS", 2, 3.1);
    got = dict((root spawn retrieve_student(id=s["id"])).reports[0]);
    assert got["fullname"] == "bob" + tag and got["id"] == s["id"];
    assert (root spawn retrieve_student(id="no-such-id")).reports[0] is None;
}

test "list contains every added student" {
    tag = uuid.uuid4().hex[:8];
    ids = [add(n + tag, "Math", 1, 2.5)["id"] for n in ["c", "d", "e"]];
    listed = [x["id"] for x in all_students()];
    for i in ids {
        assert i in listed;
    }
}

test "partial update only sets supplied fields" {
    tag = uuid.uuid4().hex[:8];
    s = add("eve" + tag, "Physics", 3, 3.0);
    u = dict((root spawn update_student_data(id=s["id"], gpa=3.9, course_of_study="Astrophysics")).reports[0]);
    assert abs(u["gpa"] - 3.9) < 1e-9 and u["course_of_study"] == "Astrophysics";
    assert u["fullname"] == "eve" + tag and u["year"] == 3;
    again = dict((root spawn retrieve_student(id=s["id"])).reports[0]);
    assert abs(again["gpa"] - 3.9) < 1e-9 and again["course_of_study"] == "Astrophysics" and again["year"] == 3;
    u2 = dict((root spawn update_student_data(id=s["id"], year=4)).reports[0]);
    assert u2["year"] == 4 and abs(u2["gpa"] - 3.9) < 1e-9;
}

test "update of missing student reports False" {
    assert (root spawn update_student_data(id="nope", gpa=1.0)).reports[0] == False;
}

test "delete removes exactly that student" {
    tag = uuid.uuid4().hex[:8];
    a = add("fay" + tag, "Art", 1, 2.0);
    b = add("gus" + tag, "Art", 1, 2.0);
    before = len(all_students());
    assert (root spawn delete_student(id=a["id"])).reports[0] == True;
    listed = [x["id"] for x in all_students()];
    assert a["id"] not in listed and b["id"] in listed;
    assert len(listed) == before - 1;
    assert (root spawn retrieve_student(id=a["id"])).reports[0] is None;
    assert (root spawn delete_student(id=a["id"])).reports[0] == False;
}
