import from main { cast_vote }

test "revote moves the ballot" {
    root spawn cast_vote(poll="unit-poll", voter="sam", choice="Pizza");
    r = (root spawn cast_vote(poll="unit-poll", voter="sam", choice="sushi")).reports[0];
    assert "pizza" not in r["tallies"];
    assert r["tallies"]["sushi"] >= 1;
}
