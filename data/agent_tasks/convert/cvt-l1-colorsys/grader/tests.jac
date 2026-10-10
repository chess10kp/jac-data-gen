# Hidden tests: CPython Lib/test/test_colorsys.py (v3.12.7) ported to Jac.
import from color_spaces { rgb_to_yiq, yiq_to_rgb, rgb_to_hls, hls_to_rgb, rgb_to_hsv, hsv_to_rgb }

def close3(a: tuple[float, float, float], b: tuple[float, float, float]) -> bool {
    return len(a) == 3 and len(b) == 3 and all(abs(a[k] - b[k]) < 1e-7 for k in range(3));
}

def grid -> list[tuple[float, float, float]] {
    steps: list[float] = [];
    x = 0.0;
    while x <= 1.0 {
        steps.append(x);
        x += 0.2;
    }
    return [(r, g, b) for r in steps for g in steps for b in steps];
}

glob HSV_VALUES: list[tuple[tuple[float, float, float], tuple[float, float, float]]] = [
    ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0)),
    ((0.0, 0.0, 1.0), (4.0 / 6.0, 1.0, 1.0)),
    ((0.0, 1.0, 0.0), (2.0 / 6.0, 1.0, 1.0)),
    ((0.0, 1.0, 1.0), (3.0 / 6.0, 1.0, 1.0)),
    ((1.0, 0.0, 0.0), (0.0, 1.0, 1.0)),
    ((1.0, 0.0, 1.0), (5.0 / 6.0, 1.0, 1.0)),
    ((1.0, 1.0, 0.0), (1.0 / 6.0, 1.0, 1.0)),
    ((1.0, 1.0, 1.0), (0.0, 0.0, 1.0)),
    ((0.5, 0.5, 0.5), (0.0, 0.0, 0.5))
];

glob HLS_VALUES: list[tuple[tuple[float, float, float], tuple[float, float, float]]] = [
    ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0)),
    ((0.0, 0.0, 1.0), (4.0 / 6.0, 0.5, 1.0)),
    ((0.0, 1.0, 0.0), (2.0 / 6.0, 0.5, 1.0)),
    ((0.0, 1.0, 1.0), (3.0 / 6.0, 0.5, 1.0)),
    ((1.0, 0.0, 0.0), (0.0, 0.5, 1.0)),
    ((1.0, 0.0, 1.0), (5.0 / 6.0, 0.5, 1.0)),
    ((1.0, 1.0, 0.0), (1.0 / 6.0, 0.5, 1.0)),
    ((1.0, 1.0, 1.0), (0.0, 1.0, 0.0)),
    ((0.5, 0.5, 0.5), (0.0, 0.5, 0.0))
];

glob YIQ_VALUES: list[tuple[tuple[float, float, float], tuple[float, float, float]]] = [
    ((0.0, 0.0, 0.0), (0.0, 0.0, 0.0)),
    ((0.0, 0.0, 1.0), (0.11, -0.3217, 0.3121)),
    ((0.0, 1.0, 0.0), (0.59, -0.2773, -0.5251)),
    ((0.0, 1.0, 1.0), (0.7, -0.599, -0.213)),
    ((1.0, 0.0, 0.0), (0.3, 0.599, 0.213)),
    ((1.0, 0.0, 1.0), (0.41, 0.2773, 0.5251)),
    ((1.0, 1.0, 0.0), (0.89, 0.3217, -0.3121)),
    ((1.0, 1.0, 1.0), (1.0, 0.0, 0.0)),
    ((0.5, 0.5, 0.5), (0.5, 0.0, 0.0))
];

test "hsv roundtrip" {
    for rgb in grid() {
        (h, s, v) = rgb_to_hsv(rgb[0], rgb[1], rgb[2]);
        assert close3(rgb, hsv_to_rgb(h, s, v));
    }
}

test "hsv values" {
    for (rgb, hsv) in HSV_VALUES {
        assert close3(hsv, rgb_to_hsv(rgb[0], rgb[1], rgb[2]));
        assert close3(rgb, hsv_to_rgb(hsv[0], hsv[1], hsv[2]));
    }
}

test "hls roundtrip" {
    for rgb in grid() {
        (h, l, s) = rgb_to_hls(rgb[0], rgb[1], rgb[2]);
        assert close3(rgb, hls_to_rgb(h, l, s));
    }
}

test "hls values" {
    for (rgb, hls) in HLS_VALUES {
        assert close3(hls, rgb_to_hls(rgb[0], rgb[1], rgb[2]));
        assert close3(rgb, hls_to_rgb(hls[0], hls[1], hls[2]));
    }
}

test "hls near white (gh-106498)" {
    assert close3((0.5, 1.0, 1.0), rgb_to_hls(0.9999999999999999, 1.0, 1.0));
    assert close3((1.0, 1.0, 1.0), hls_to_rgb(0.5, 1.0, 1.0));
    assert close3((0.0, 1.0, 1.0), rgb_to_hls(1.0, 0.9999999999999999, 0.9999999999999999));
    assert close3((1.0, 1.0, 1.0), hls_to_rgb(0.0, 1.0, 1.0));
}

test "yiq roundtrip" {
    for rgb in grid() {
        (y, i, q) = rgb_to_yiq(rgb[0], rgb[1], rgb[2]);
        assert close3(rgb, yiq_to_rgb(y, i, q));
    }
}

test "yiq values" {
    for (rgb, yiq) in YIQ_VALUES {
        assert close3(yiq, rgb_to_yiq(rgb[0], rgb[1], rgb[2]));
        assert close3(rgb, yiq_to_rgb(yiq[0], yiq[1], yiq[2]));
    }
}

test "yiq_to_rgb clamps to the unit cube" {
    assert close3((1.0, 0.0, 1.0), yiq_to_rgb(0.5, 0.0, 1.0));
    assert close3((0.0, 1.0, 0.0), yiq_to_rgb(0.5, 0.0, -1.0));
}
