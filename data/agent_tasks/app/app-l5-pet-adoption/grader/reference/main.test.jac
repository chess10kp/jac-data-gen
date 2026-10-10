test "adoption flow" {
    p = (root spawn add_pet(name="Unit Biscuit", species="Dog", age_years=2)).reports[0];
    assert p["species"] == "dog" and p["status"] == "available";
    a = (root spawn adopt(pet_id=p["id"], adopter="unit-ann")).reports[0];
    assert a["status"] == "adopted";
    again = (root spawn adopt(pet_id=p["id"], adopter="unit-bob")).reports[0];
    assert "error" in list(again);
    mine = (root spawn adopter_pets(adopter="unit-ann")).reports[0];
    assert list([x["name"] for x in mine]) == ["Unit Biscuit"];
}
