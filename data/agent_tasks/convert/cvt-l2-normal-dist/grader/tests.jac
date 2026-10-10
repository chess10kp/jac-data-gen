# Hidden tests: CPython Lib/test/test_statistics.py TestNormalDist (v3.12.7) ported to Jac.
import math;
import from normal_dist { NormalDist, StatisticsError }

def near(a: float, b: float, places: int = 7) -> bool {
    return round(abs(a - b), places) == 0;
}

def stat_error(f: any) -> bool {
    try {
        f();
    } except StatisticsError {
        return True;
    }
    return False;
}

def type_error(f: any) -> bool {
    try {
        f();
    } except TypeError {
        return True;
    }
    return False;
}

test "instantiation and attributes" {
    nd = NormalDist(500, 17);
    assert nd.mean == 500 and nd.stdev == 17 and nd.variance == 17 ** 2;
    nd0 = NormalDist();
    assert nd0.mean == 0 and nd0.stdev == 1 and nd0.variance == 1;
    assert isinstance(NormalDist(1, 2).mean, float);
    assert stat_error(lambda -> any { return NormalDist(500, -10); });
    assert issubclass(StatisticsError, ValueError);
}

test "from_samples" {
    data = [96, 107, 90, 92, 110];
    assert NormalDist.from_samples(data) == NormalDist(99, 9);
    assert NormalDist.from_samples([float(v) for v in tuple(data)]) == NormalDist(99, 9);
    assert stat_error(lambda -> any { return NormalDist.from_samples([]); });
    assert stat_error(lambda -> any { return NormalDist.from_samples([10]); });
}

test "pdf" {
    X = NormalDist(100, 15);
    assert X.pdf(99) < X.pdf(100) and X.pdf(101) < X.pdf(100);
    for i in range(50) {
        assert near(X.pdf(100 - i), X.pdf(100 + i));
    }
    dx = 2.0 ** -10;
    for x in range(90, 111) {
        est = (X.cdf(x + dx) - X.cdf(x)) / dx;
        assert near(X.pdf(x), est, 4);
    }
    Z = NormalDist();
    table = [0.3989, 0.3989, 0.3989, 0.3988, 0.3986, 0.3984, 0.3982, 0.3980, 0.3977, 0.3973,
             0.3970, 0.3965, 0.3961, 0.3956, 0.3951, 0.3945, 0.3939, 0.3932, 0.3925, 0.3918,
             0.3910, 0.3902, 0.3894, 0.3885, 0.3876, 0.3867, 0.3857, 0.3847, 0.3836, 0.3825,
             0.3814, 0.3802, 0.3790, 0.3778, 0.3765, 0.3752, 0.3739, 0.3725, 0.3712, 0.3697,
             0.3683, 0.3668, 0.3653, 0.3637, 0.3621, 0.3605, 0.3589, 0.3572, 0.3555, 0.3538];
    for (x, px) in enumerate(table) {
        assert near(Z.pdf(x / 100.0), px, 4);
        assert near(Z.pdf(-x / 100.0), px, 4);
    }
    assert stat_error(lambda -> any { return NormalDist(100, 0).pdf(90); });
    assert X.pdf(float("-Inf")) == 0.0 and X.pdf(float("Inf")) == 0.0;
    assert math.isnan(X.pdf(float("NaN")));
}

test "cdf" {
    X = NormalDist(100, 15);
    cdfs = [X.cdf(x) for x in range(1, 200)];
    assert cdfs == sorted(cdfs);
    assert X.cdf(100) == 0.5;
    Z = NormalDist();
    for (z, cum) in [(0.00, 0.50000), (0.01, 0.50399), (0.02, 0.50798), (0.14, 0.55567),
                     (0.29, 0.61409), (0.33, 0.62930), (0.54, 0.70540), (0.60, 0.72575),
                     (1.17, 0.87900), (1.60, 0.94520), (2.05, 0.97982), (2.89, 0.99807),
                     (3.52, 0.99978), (3.98, 0.99997), (4.07, 0.99998)] {
        assert near(Z.cdf(z), cum, 5);
        assert near(Z.cdf(-z), 1.0 - cum, 5);
    }
    assert stat_error(lambda -> any { return NormalDist(100, 0).cdf(90); });
    assert X.cdf(float("-Inf")) == 0.0 and X.cdf(float("Inf")) == 1.0;
    assert math.isnan(X.cdf(float("NaN")));
}

test "inv_cdf" {
    iq = NormalDist(100, 15);
    assert iq.inv_cdf(0.5) == iq.mean;
    Z = NormalDist();
    pp: dict[float, list[float]] = {
        5.0: [0.000, 1.645, 2.576, 3.291, 3.891, 4.417, 4.892, 5.327, 5.731, 6.109],
        2.5: [0.674, 1.960, 2.807, 3.481, 4.056, 4.565, 5.026, 5.451, 5.847, 6.219],
        1.0: [1.282, 2.326, 3.090, 3.719, 4.265, 4.753, 5.199, 5.612, 5.998, 6.361]
    };
    for (base, row) in pp.items() {
        for (k, x) in enumerate(row, start=1) {
            p = base * 10.0 ** (-k);
            assert near(-Z.inv_cdf(p), x, 3);
            assert near(Z.inv_cdf(1.0 - p), x, 3);
        }
    }
    assert near(NormalDist(40, 1.5).inv_cdf(0.908789), 42.000002);
    n = 2 ** 12;
    for i in range(1, n) {
        p = i / n;
        assert near(iq.cdf(iq.inv_cdf(p)), p);
    }
    for e in range(1, 51) {
        p = 2.0 ** (-e);
        assert near(iq.cdf(iq.inv_cdf(p)), p);
        assert near(iq.cdf(iq.inv_cdf(1.0 - p)), 1.0 - p);
    }
    for x in range(200) {
        assert near(iq.inv_cdf(iq.cdf(x)), x, 5);
    }
    for bad in [0.0, -0.1, 1.0, 1.1] {
        assert stat_error(lambda -> any { return iq.inv_cdf(bad); });
    }
    assert NormalDist(100, 0).inv_cdf(0.5) == 100;
    assert math.isnan(Z.inv_cdf(float("NaN")));
}

test "quantiles" {
    Z = NormalDist();
    assert len(Z.quantiles(n=1)) == 0;
    for (n, expected) in [(2, [0.0]), (3, [-0.4307, 0.4307]), (4, [-0.6745, 0.0, 0.6745])] {
        actual = Z.quantiles(n=n);
        assert len(actual) == len(expected);
        assert all(math.isclose(e, a, abs_tol=0.0001) for (e, a) in zip(expected, actual));
    }
    assert len(Z.quantiles()) == 3;
}

def overlap_numeric(X: NormalDist, Y: NormalDist) -> float {
    steps = 8192;
    center = (X.mean + Y.mean) / 2.0;
    width = 5 * max(X.stdev, Y.stdev);
    start = center - width;
    dx = 2.0 * width / steps;
    xs = [start + i * dx for i in range(steps)];
    xp = [X.pdf(x) for x in xs];
    yp = [Y.pdf(x) for x in xs];
    total = max(math.fsum(xp), math.fsum(yp));
    return math.fsum([min(a, b) for (a, b) in zip(xp, yp)]) / total;
}

test "overlap" {
    for (X1, X2, published) in [(NormalDist(0.0, 2.0), NormalDist(1.0, 2.0), 0.80258),
                          (NormalDist(0.0, 1.0), NormalDist(1.0, 2.0), 0.60993)] {
        assert near(X1.overlap(X2), published, 4);
        assert near(X2.overlap(X1), published, 4);
    }
    assert NormalDist(2.4, 1.6).overlap(NormalDist(3.2, 2.0)) == 0.8035050657330205;
    pairs = [(NormalDist(70, 4), NormalDist(65, 3.5)), (NormalDist(100, 15), NormalDist(110, 15)),
             (NormalDist(-100, 15), NormalDist(110, 15)), (NormalDist(-100, 15), NormalDist(-110, 15)),
             (NormalDist(100, 12), NormalDist(100, 15)), (NormalDist(100, 12), NormalDist(110, 15)),
             (NormalDist(100, 12), NormalDist(150, 15)), (NormalDist(100, 12), NormalDist(150, 35)),
             (NormalDist(1.000, 0.002), NormalDist(1.001, 0.003)),
             (NormalDist(1.000, 0.002), NormalDist(1.006, 0.0003)),
             (NormalDist(1.000, 0.002), NormalDist(1.001, 0.099))];
    for (X1, X2) in pairs {
        want = overlap_numeric(X1, X2);
        assert near(X1.overlap(X2), want, 5);
        assert near(X2.overlap(X1), want, 5);
    }
    X = NormalDist();
    nothing: any = None;
    assert type_error(lambda -> any { return X.overlap(nothing); });
    assert stat_error(lambda -> any { return X.overlap(NormalDist(1, 0)); });
    assert stat_error(lambda -> any { return NormalDist(1, 0).overlap(X); });
}

test "zscore" {
    X = NormalDist(100, 15);
    assert X.zscore(142) == 2.8 and X.zscore(58) == -2.8 and X.zscore(100) == 0.0;
    nothing: any = None;
    assert type_error(lambda -> any { return X.zscore(nothing); });
    assert stat_error(lambda -> any { return NormalDist(1, 0).zscore(100); });
}

test "properties" {
    X = NormalDist(100, 15);
    assert X.mean == 100 and X.median == 100 and X.mode == 100;
    assert X.stdev == 15 and X.variance == 225;
}

test "same type addition and subtraction" {
    X = NormalDist(100, 12);
    Y = NormalDist(40, 5);
    assert X + Y == NormalDist(140, 13);
    assert X - Y == NormalDist(60, 13);
}

test "translation and scaling" {
    X = NormalDist(100, 15);
    y = 10;
    assert +X == NormalDist(100, 15);
    assert -X == NormalDist(-100, 15);
    assert X + y == NormalDist(110, 15);
    assert y + X == NormalDist(110, 15);
    assert X - y == NormalDist(90, 15);
    assert y - X == NormalDist(-90, 15);
    assert X * y == NormalDist(1000, 150);
    assert y * X == NormalDist(1000, 150);
    assert X / y == NormalDist(10, 1.5);
    assert X * -2 == NormalDist(-200, 30);
    ten: any = 10;
    assert type_error(lambda -> any { return ten / X; });
}

test "unary operations make copies" {
    X = NormalDist(100, 12);
    Y = +X;
    assert X is not Y and X.mean == Y.mean and X.stdev == Y.stdev;
    Y = -X;
    assert X is not Y and X.mean == -Y.mean and X.stdev == Y.stdev;
}

test "equality" {
    nd1 = NormalDist();
    nd2 = NormalDist(2, 4);
    assert nd1 != nd2;
    assert nd1 == NormalDist();
    assert nd2 == NormalDist(2, 4);
    assert nd2 != NormalDist(2, 8);
    assert nd2 != NormalDist(8, 4);
    assert nd1.__eq__(5) is NotImplemented;
    assert nd1 != "NormalDist(mu=0.0, sigma=1.0)";
}

test "hashability" {
    s = {NormalDist(100, 15), NormalDist(100.0, 15.0), NormalDist(100, 10), NormalDist(95, 15), NormalDist(100, 15)};
    assert len(s) == 3;
}

test "repr" {
    assert repr(NormalDist(37.5, 5.625)) == "NormalDist(mu=37.5, sigma=5.625)";
    assert repr(NormalDist(100, 15)) == "NormalDist(mu=100.0, sigma=15.0)";
}
