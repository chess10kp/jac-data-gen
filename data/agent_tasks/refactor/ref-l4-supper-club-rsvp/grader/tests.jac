import from rsvp { rsvp, set_capacity, headcount, guests, agenda, cancel }

test "input validation" {
    assert rsvp("harvest", "  ", "yes") == "guest required";
    assert rsvp("harvest", "Kim", "sure") == "bad answer";
    assert rsvp("harvest", "Kim", "yes", 4) == "plus_ones out of range";
    assert rsvp("harvest", "Kim", "yes", -1) == "plus_ones out of range";
    assert headcount("harvest") == 0;
    assert len(guests("harvest", "yes")) == 0;
    assert rsvp("harvest", "Kim", "yes", 3) == "ok";
    assert headcount("harvest") == 4;
}

test "headcount counts yes answers and their plus ones only" {
    rsvp("harvest", "Kim", "yes", 2);
    rsvp("harvest", "lou", "maybe", 1);
    rsvp("harvest", "Ana", "no", 3);
    rsvp("harvest", "Bo", "yes");
    assert headcount("harvest") == 4;
    assert guests("harvest", "yes") == ["Bo", "Kim"];
    assert guests("harvest", "maybe") == ["lou"];
    assert guests("harvest", "no") == ["Ana"];
    assert len(guests("harvest", "later")) == 0;
    assert headcount("nope") == 0;
}

test "answering again replaces the answer and the spelling" {
    rsvp("harvest", "Kim", "yes", 2);
    assert rsvp("harvest", " kim ", "no") == "ok";
    assert headcount("harvest") == 0;
    assert guests("harvest", "no") == ["kim"];
    assert len(guests("harvest", "yes")) == 0;
    rsvp("harvest", "KIM", "yes", 1);
    assert headcount("harvest") == 2;
    assert guests("harvest", "yes") == ["KIM"];
}

test "capacity caps yes answers" {
    assert set_capacity("tasting", 5);
    assert rsvp("tasting", "Kim", "yes", 2) == "ok";
    assert rsvp("tasting", "Lou", "yes", 2) == "full";
    assert rsvp("tasting", "Lou", "yes", 1) == "ok";
    assert rsvp("tasting", "Ana", "yes") == "full";
    assert rsvp("tasting", "Ana", "maybe", 3) == "ok";
    assert rsvp("tasting", "Kim", "yes", 3) == "full";
    assert rsvp("tasting", "Kim", "yes", 1) == "ok";
    assert headcount("tasting") == 4;
    assert not set_capacity("tasting", 3);
    assert set_capacity("tasting", 0);
    assert rsvp("tasting", "Ana", "yes", 3) == "ok";
    assert headcount("tasting") == 8;
}

test "agenda lists yes and maybe across events" {
    rsvp("harvest", "Kim", "yes");
    rsvp("tasting", "kim", "maybe");
    rsvp("brunch", "Kim", "no");
    rsvp("brunch", "Lou", "yes");
    assert agenda("KIM") == ["harvest (yes)", "tasting (maybe)"];
    assert agenda("lou") == ["brunch (yes)"];
    assert len(agenda("nobody")) == 0;
}

test "cancelling removes one answer" {
    rsvp("harvest", "Kim", "yes", 1);
    rsvp("tasting", "Kim", "yes");
    rsvp("harvest", "Lou", "yes");
    assert cancel("harvest", "kim");
    assert not cancel("harvest", "kim");
    assert not cancel("gala", "Lou");
    assert not cancel("harvest", "Zed");
    assert headcount("harvest") == 1;
    assert agenda("Kim") == ["tasting (yes)"];
    assert guests("harvest", "yes") == ["Lou"];
}
