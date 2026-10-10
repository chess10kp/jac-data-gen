import uuid;
import from main { add_pet, list_available, adopt, adopter_pets }

def get(x: any, k: str) -> any {
    return x[k] if isinstance(x, dict) else getattr(x, k);
}

def idof(x: any) -> str {
    if isinstance(x, dict) {
        return x["id"] if "id" in x else x["_jac_id"];
    }
    return jid(x);
}

def flat(rs: list[any]) -> list[any] {
    if len(rs) == 1 and isinstance(rs[0], list) {
        return rs[0];
    }
    return rs;
}

def add(n: str, s: str, age: int) -> any {
    return (root spawn add_pet(name=n, species=s, age_years=age)).reports[0];
}

test "add pet view" {
    n = "Mochi" + uuid.uuid4().hex[:6];
    p = add(n, "Cat", 3);
    assert get(p, "name") == n and get(p, "species") == "cat";
    assert get(p, "age_years") == 3 and get(p, "status") == "available";
    assert len(idof(p)) > 0;
}

test "list available filters and orders" {
    tag = uuid.uuid4().hex[:6];
    add("Rex" + tag, "dog", 5);
    add("Ace" + tag, "dog", 1);
    add("Bo" + tag, "dog", 1);
    add("Tom" + tag, "cat", 0);
    dogs = [get(p, "name") for p in flat((root spawn list_available(species="DOG")).reports) if get(p, "name").endswith(tag)];
    assert list(dogs) == ["Ace" + tag, "Bo" + tag, "Rex" + tag];
    everyone = [get(p, "name") for p in flat((root spawn list_available()).reports) if get(p, "name").endswith(tag)];
    assert list(everyone) == ["Tom" + tag, "Ace" + tag, "Bo" + tag, "Rex" + tag];
}

test "adopt and history" {
    tag = uuid.uuid4().hex[:6];
    who = "ann-" + tag;
    p1 = add("Zed" + tag, "rabbit", 2);
    p2 = add("Amy" + tag, "rabbit", 4);
    r = (root spawn adopt(pet_id=idof(p1), adopter=who)).reports[0];
    assert get(r, "status") == "adopted";
    root spawn adopt(pet_id=idof(p2), adopter=who);
    left = [get(p, "name") for p in flat((root spawn list_available(species="rabbit")).reports) if get(p, "name").endswith(tag)];
    assert len(left) == 0;
    hist = [get(p, "name") for p in flat((root spawn adopter_pets(adopter=who)).reports)];
    assert list(hist) == ["Amy" + tag, "Zed" + tag];
    assert len(flat((root spawn adopter_pets(adopter="nobody-" + tag)).reports)) == 0;
}

test "adoption errors" {
    tag = uuid.uuid4().hex[:6];
    p = add("Kit" + tag, "cat", 1);
    root spawn adopt(pet_id=idof(p), adopter="a-" + tag);
    again = (root spawn adopt(pet_id=idof(p), adopter="b-" + tag)).reports[0];
    assert isinstance(again, dict) and "error" in list(again);
    ghost = (root spawn adopt(pet_id="nope" + tag, adopter="b-" + tag)).reports[0];
    assert isinstance(ghost, dict) and "error" in list(ghost);
    assert len(flat((root spawn adopter_pets(adopter="b-" + tag)).reports)) == 0;
}
