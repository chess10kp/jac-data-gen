obj Point {
    has x: int = 0;
    has y: int = 0;
}

def example(value: any) {
    match value {
        case 0:
            print("zero");

        case 1 | 2 | 3:
            print("small");

        case [x, y]:
            print(f"pair: {x}, {y}");

        case {"key": v}:
            print(f"dict with key: {v}");

        case Point(x=x, y=y):
            print(f"point at {x}, {y}");

        case _:
            print("default");
    }
}
