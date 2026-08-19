def shape_areas(shapes: list[list]) -> list[float] {
    out: list[float] = [];
    for s in shapes {
        match s {
            case ["sq", x]: out.append(float(x * x));
            case ["rect", w, h]: out.append(float(w * h));
            case ["tri", b, h]: out.append(b * h / 2);
            case _: out.append(0.0);
        }
    }
    return out;
}

with entry {
    print(shape_areas([['sq', 3], ['rect', 2, 4], ['tri', 3, 4]]));
}
