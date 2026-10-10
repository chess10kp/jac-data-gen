import from main { add_spot, park, where, leave, level_free, takings }

def setup {
    add_spot("2A", 2, "standard");
    add_spot("1B", 1, "standard");
    add_spot("1A", 1, "standard");
    add_spot("1E", 1, "ev");
    add_spot("2E", 2, "ev");
}

test "spots are unique and kinds validated" {
    assert add_spot("1A", 1, "standard");
    assert not add_spot("1A", 2, "ev");
    assert not add_spot("1X", 1, "valet");
    assert add_spot("1E", 1, "ev");
    assert level_free(1) == 2;
    assert level_free(5) == 0;
    assert takings(1) == 0;
}

test "cars fill the lowest level first" {
    setup();
    assert park("abc 1", 0, False) == "1A";
    assert park("xyz", 0, False) == "1B";
    assert park(" ABC 1 ", 5, False) == "";
    assert park("q1", 0, False) == "2A";
    assert park("q2", 0, False) == "";
    assert level_free(1) == 1;
    assert level_free(2) == 1;
    assert where("Abc 1") == "1A";
    assert where("nope") == "";
}

test "ev drivers prefer charging spots then fall back" {
    setup();
    assert park("e1", 0, True) == "1E";
    assert park("e2", 0, True) == "2E";
    assert park("e3", 0, True) == "1A";
    assert park("s1", 0, False) == "1B";
    assert park("s2", 0, False) == "2A";
    assert park("s3", 0, False) == "";
    assert leave("e1", 10) == 0;
    assert park("s3", 20, False) == "";
    assert park("e4", 20, True) == "1E";
}

test "fees and takings per level" {
    setup();
    park("a", 0, False);
    park("b", 0, False);
    park("c", 0, False);
    assert leave("a", 30) == 0;
    assert leave("b", 31) == 200;
    assert leave("c", 100) == 2 * 200;
    assert leave("c", 200) == -1;
    assert takings(1) == 200;
    assert takings(2) == 400;
    assert level_free(1) == 3;
}

test "leaving frees the spot and rejects bad times" {
    setup();
    park("a", 50, False);
    assert leave("a", 40) == -1;
    assert where("a") == "1A";
    assert leave("A", 170) == 400;
    assert where("a") == "";
    assert leave("zz", 10) == -1;
    assert park("b", 200, False) == "1A";
    assert park("a", 210, False) == "1B";
    assert where("a") == "1B";
}
