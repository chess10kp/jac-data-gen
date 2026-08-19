obj Box { has size: int = 0; }

enum Crate: Box {
    SMALL = Box(size=1),
    LARGE = Box(size=10)
}
