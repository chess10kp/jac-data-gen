"""Drying shelves in a pottery studio: each shelf holds a limited number of pieces."""

node Shelf {
    has name: str;
    has capacity: int;
}

node Piece {
    has maker: str;
    has kg: float;
}

def find_shelf(name: str) -> Shelf | None {
    wanted = name;
    found = [root -->[?:Shelf, name == wanted]];
    return found[0] if found else None;
}

def add_shelf(name: str, capacity: int) -> bool {
    if find_shelf(name) is not None {
        return False;
    }
    root ++> Shelf(name=name, capacity=capacity);
    return True;
}

def place_piece(shelf: str, maker: str, kg: float) -> bool {
    s = find_shelf(shelf);
    if s is None or len([s -->[?:Piece]]) >= s.capacity {
        return False;
    }
    s ++> Piece(maker=maker, kg=kg);
    return True;
}

def shelf_load(shelf: str) -> float {
    s = find_shelf(shelf);
    if s is None {
        return 0.0;
    }
    return sum([p.kg for p in [s -->[?:Piece]]], 0.0);
}

def shelves_holding(maker: str) -> list[str] {
    who = maker;
    return sorted([s.name for s in [root -->[?:Shelf]] if [s -->[?:Piece, maker == who]]]);
}

def collect(maker: str) -> int {
    who = maker;
    removed = 0;
    for s in [root -->[?:Shelf]] {
        mine = [s -->[?:Piece, maker == who]];
        removed += len(mine);
        for p in mine {
            del p;
        }
    }
    return removed;
}

def free_slots() -> int {
    return sum([s.capacity - len([s -->[?:Piece]]) for s in [root -->[?:Shelf]]]);
}
