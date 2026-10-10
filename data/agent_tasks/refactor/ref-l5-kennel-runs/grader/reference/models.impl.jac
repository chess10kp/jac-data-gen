impl size_named(name: str) -> Size | None {
    for s in Size {
        if s.value == name {
            return s;
        }
    }
    return None;
}

impl size_rank(s: Size) -> int {
    order: list[Size] = [Size.SMALL, Size.MEDIUM, Size.LARGE];
    return order.index(s);
}

impl Run.rank -> int {
    return size_rank(self.size);
}

impl Run.free_for(start: int, nights: int) -> bool {
    return not any([s.covers(start, nights) for s in [self ->:Hosts:->]]);
}

impl Stay.covers(start: int, nights: int) -> bool {
    return self.start < start + nights and start < self.start + self.nights;
}
