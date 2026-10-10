import from main { rsvp }

test "changing an rsvp replaces it" {
    root spawn rsvp(event="unit-picnic", guest="Kim", attending=True, plus_ones=2);
    s = (root spawn rsvp(event="unit-picnic", guest=" kim ", attending=False)).reports[0];
    assert "kim" in s["declined"];
    assert "Kim" not in s["attending"];
}

test "too many plus ones" {
    s = (root spawn rsvp(event="unit-picnic", guest="Lou", attending=True, plus_ones=4)).reports[0];
    assert "error" in s;
}
