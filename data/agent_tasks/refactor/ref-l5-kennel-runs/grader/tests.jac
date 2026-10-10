import from main { add_run, reprice, book, check_out, occupancy, free_runs, bill }

def setup {
    add_run("S1", "small", 30);
    add_run("M1", "medium", 40);
    add_run("L2", "large", 55);
    add_run("L1", "large", 50);
}

test "runs are unique and sizes validated" {
    assert add_run("S1", "small", 30);
    assert not add_run("S1", "large", 30);
    assert not add_run("X1", "huge", 30);
    assert not add_run("X2", "small", -1);
    assert reprice("S1", 35);
    assert not reprice("nope", 10);
    assert free_runs("small", 1, 1) == 1;
}

test "booking picks the smallest free run that fits" {
    setup();
    assert book("rex", "small", 1, 3) == "S1";
    assert book("ada", "small", 2, 1) == "M1";
    assert book("bo", "medium", 3, 2) == "L1";
    assert book("zed", "large", 1, 5) == "L2";
    assert book("ivy", "large", 4, 1) == "";
    assert book("pip", "small", 4, 2) == "S1";
    assert book("odd", "tiny", 1, 1) == "";
    assert book("odd", "small", 9, 0) == "";
}

test "occupancy and vacancy for a night" {
    setup();
    book("rex", "small", 1, 3);
    book("bo", "medium", 3, 2);
    book("lu", "large", 6, 1);
    assert occupancy(3) == ["M1:bo", "S1:rex"];
    assert occupancy(4) == ["M1:bo"];
    assert len(occupancy(5)) == 0;
    assert free_runs("small", 3, 1) == 2;
    assert free_runs("medium", 2, 3) == 2;
    assert free_runs("large", 5, 2) == 1;
    assert free_runs("tiny", 1, 1) == 0;
}

test "check out removes only that dog's stays" {
    setup();
    assert book("rex", "small", 1, 2) == "S1";
    assert book("rex", "small", 5, 2) == "S1";
    assert book("bo", "small", 3, 2) == "S1";
    assert check_out("rex") == 2;
    assert check_out("rex") == 0;
    assert occupancy(3) == ["S1:bo"];
    assert len(occupancy(1)) == 0;
    assert book("ada", "small", 1, 1) == "S1";
    assert free_runs("small", 3, 1) == 3;
    assert free_runs("small", 5, 2) == 4;
}

test "bills use the price locked at booking" {
    setup();
    book("rex", "small", 1, 3);
    reprice("S1", 100);
    book("rex", "small", 4, 2);
    book("bo", "large", 1, 2);
    assert bill("rex") == 3 * 30 + 2 * 100;
    assert bill("bo") == 2 * 50;
    assert bill("ghost") == 0;
    check_out("bo");
    assert bill("bo") == 0;
}
