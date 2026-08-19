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
        case [first, *rest]:
            print(f"list starting with {first}, rest {rest}");
        case {"key": v}:
            print(f"dict with key: {v}");
        case Point(x=px, y=py):
            print(f"point at {px}, {py}");
        case _:
            print("default");
    }
}
