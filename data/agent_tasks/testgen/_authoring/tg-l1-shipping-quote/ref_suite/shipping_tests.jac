import from shipping { RATES, billable_weight, quote, free_shipping }

def near(a: float, b: float) -> bool {
    return abs(a - b) < 1e-6;
}

test "actual weight rounds up to the next half kilo" {
    assert near(billable_weight(1.0, 1, 1, 1), 1.0);
    assert near(billable_weight(1.01, 1, 1, 1), 1.5);
    assert near(billable_weight(1.5, 1, 1, 1), 1.5);
    assert near(billable_weight(1.51, 1, 1, 1), 2.0);
    assert near(billable_weight(0.2, 1, 1, 1), 0.5);
}

test "volumetric weight wins when larger" {
    assert near(billable_weight(1.0, 50, 50, 20), 10.0);
    assert near(billable_weight(1.0, 10, 10, 26), 1.0);
    assert near(billable_weight(1.0, 30, 30, 30), 5.5);
    assert near(billable_weight(9.0, 30, 30, 30), 9.0);
}

test "non-positive inputs rejected" {
    for args in [(0.0, 1.0, 1.0, 1.0), (1.0, 0.0, 1.0, 1.0), (1.0, 1.0, -1.0, 1.0), (1.0, 1.0, 1.0, 0.0)] {
        with testraises(ValueError) {
            billable_weight(args[0], args[1], args[2], args[3]);
        }
    }
}

test "first kilo is the base price" {
    assert near(quote(1.0, "domestic"), 5.0);
    assert near(quote(0.5, "regional"), 9.0);
    assert near(quote(1.0, "international"), 20.0);
}

test "per kilo charges above one kilo" {
    assert near(quote(2.0, "domestic"), 6.2);
    assert near(quote(3.5, "domestic"), 8.0);
    assert near(quote(4.0, "regional"), 15.0);
    assert near(quote(2.5, "international"), 26.75);
}

test "quotes are rounded to cents" {
    q = quote(1.3333, "domestic");
    assert near(q, 5.4);
}

test "quote errors" {
    with testraises(ValueError) {
        quote(1.0, "mars");
    }
    with testraises(ValueError) {
        quote(0.0, "domestic");
    }
    with testraises(ValueError) {
        quote(-2.0, "regional");
    }
}

test "free shipping thresholds" {
    assert free_shipping(50.0, "domestic") == True;
    assert free_shipping(49.99, "domestic") == False;
    assert free_shipping(100.0, "regional") == True;
    assert free_shipping(99.99, "regional") == False;
    assert free_shipping(60.0, "regional") == False;
    assert free_shipping(10000.0, "international") == False;
    with testraises(ValueError) {
        free_shipping(10.0, "moon");
    }
}

test "rate table" {
    assert len(RATES) == 3;
    assert RATES["regional"][0] == 9.0;
    assert RATES["regional"][1] == 2.0;
}
