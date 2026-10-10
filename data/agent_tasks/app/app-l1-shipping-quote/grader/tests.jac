import from shipping { billable_weight, quote, free_shipping }

def close(a: float, b: float) -> bool {
    return abs(a - b) < 1e-6;
}

test "billable weight uses the larger and rounds up to half kg" {
    assert close(billable_weight(2.1, 10, 10, 10), 2.5);
    assert close(billable_weight(2.5, 10, 10, 10), 2.5);
    assert close(billable_weight(3.01, 10, 10, 10), 3.5);
    # volumetric 50*40*30/5000 = 12 beats actual 3
    assert close(billable_weight(3.0, 50, 40, 30), 12.0);
    # volumetric 30*20*21/5000 = 2.52 -> 3.0
    assert close(billable_weight(1.0, 30, 20, 21), 3.0);
}

test "billable weight rejects non-positive input" {
    try {
        billable_weight(0, 10, 10, 10);
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
    try {
        billable_weight(1, 10, -2, 10);
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
}

test "quotes per zone" {
    assert close(quote(1.0, "domestic"), 5.0);
    assert close(quote(0.5, "domestic"), 5.0);
    assert close(quote(1.5, "domestic"), 5.6);
    assert close(quote(3.0, "regional"), 13.0);
    assert close(quote(2.5, "international"), 26.75);
    assert close(quote(10.0, "domestic"), 15.8);
}

test "quote rejects bad input" {
    try {
        quote(2.0, "moon");
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
    try {
        quote(0, "domestic");
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
}

test "free shipping thresholds" {
    assert free_shipping(50.0, "domestic");
    assert not free_shipping(49.99, "domestic");
    assert not free_shipping(99.0, "regional");
    assert free_shipping(100.0, "regional");
    assert not free_shipping(10000.0, "international");
    try {
        free_shipping(10.0, "nowhere");
        assert False, "expected ValueError";
    } except ValueError {
        assert True;
    }
}
