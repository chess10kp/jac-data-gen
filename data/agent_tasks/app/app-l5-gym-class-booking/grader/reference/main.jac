"""Climbing-gym class booking: Klass and Member nodes joined by Booking edges."""

node Klass {
    has name: str;
    has capacity: int;
}

node Member {
    has name: str;
}

edge Booking: Member --> Klass {}

def view(k: Klass) -> dict[str, any] {
    booked = len([k <-:Booking:<-]);
    return {"id": jid(k), "name": k.name, "capacity": k.capacity,
            "booked": booked, "spots_left": k.capacity - booked};
}

def find_class(class_id: str) -> Klass | None {
    for k in [root -->[?:Klass]] {
        if jid(k) == class_id {
            return k;
        }
    }
    return None;
}

def get_member(name: str) -> Member {
    for m in [root -->[?:Member]] {
        if m.name == name {
            return m;
        }
    }
    return root ++> Member(name=name);
}

def:pub create_class(name: str, capacity: int) -> dict[str, any] {
    if capacity < 1 {
        return {"error": "capacity must be at least 1"};
    }
    return view(root ++> Klass(name=name, capacity=capacity));
}

def:pub book_spot(class_id: str, member: str) -> dict[str, any] {
    k = find_class(class_id);
    if k is None {
        return {"error": "unknown class"};
    }
    if member in [m.name for m in [k <-:Booking:<-]] {
        return {"error": "already booked"};
    }
    if len([k <-:Booking:<-]) >= k.capacity {
        return {"error": "class is full"};
    }
    get_member(member) +>:Booking:+> k;
    return view(k);
}

def:pub cancel_booking(class_id: str, member: str) -> dict[str, any] {
    k = find_class(class_id);
    if k is None {
        return {"error": "unknown class"};
    }
    for m in [k <-:Booking:<-] {
        if m.name == member {
            del [edge m ->:Booking:-> k];
            return view(k);
        }
    }
    return {"error": "no such booking"};
}

def:pub list_classes() -> list[dict[str, any]] {
    return sorted([view(k) for k in [root -->[?:Klass]]], key=lambda (v: dict[str, any]) -> str { return v["name"]; });
}

def:pub roster(class_id: str) -> list[str] {
    k = find_class(class_id);
    if k is None {
        return [];
    }
    return sorted([m.name for m in [k <-:Booking:<-]]);
}
