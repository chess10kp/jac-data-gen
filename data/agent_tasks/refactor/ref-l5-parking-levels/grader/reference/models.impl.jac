impl kind_named(name: str) -> SpotKind | None {
    for k in SpotKind {
        if k.value == name {
            return k;
        }
    }
    return None;
}

"""First 30 minutes free, then 200 cents per started hour."""
impl fee_for(minutes: int) -> int {
    if minutes <= 30 {
        return 0;
    }
    return 200 * ((minutes + 59) // 60);
}

impl Level.free_spots(kind: SpotKind) -> list[Spot] {
    wanted = kind;
    return [s for s in [self ->:Contains:->[?:Spot, kind == wanted]] if s.is_free()];
}

impl Spot.is_free -> bool {
    return len([self ->:Occupied:->]) == 0;
}
