impl station_named(name: str) -> Station {
    wanted = name;
    found = [root -->[?:Station, name == wanted]];
    if found {
        return found[0];
    }
    return root ++> Station(name=name);
}

impl find_item(tag: str) -> Item | None {
    wanted = tag;
    found = [root -->[?:Station] ->:Holds:->[?:Item, tag == wanted]];
    return found[0] if found else None;
}

impl log_item(category: str, color: str, day: int, station: str) -> str {
    c = category_named(category);
    if c is None {
        return "";
    }
    st = station_named(station);
    tag = st.next_tag();
    st +>:Holds():+> Item(tag=tag, category=c, color=color, day=day);
    return tag;
}

impl search(category: str, color: str, since_day: int) -> list[str] {
    c = category_named(category);
    if c is None {
        return [];
    }
    w = root spawn Search(category=c, color=color, since_day=since_day);
    ordered = sorted(w.hits, key=lambda (i: Item) { (-i.day, i.tag); });
    return [i.tag for i in ordered];
}

impl claim(tag: str, name: str, day: int) -> str {
    it = find_item(tag);
    if it is None {
        return "unknown item";
    }
    if it.is_claimed() {
        return "already claimed";
    }
    wanted = name;
    people = [root -->[?:Claimant, name == wanted]];
    who = people[0] if people else root ++> Claimant(name=name);
    it +>:ClaimedBy(day=day):+> who;
    return "ok";
}

impl claims_of(name: str) -> list[str] {
    wanted = name;
    people = [root -->[?:Claimant, name == wanted]];
    if not people {
        return [];
    }
    out: list[str] = [];
    for it in [people[0] <-:ClaimedBy:<-] {
        for e in [edge it ->:ClaimedBy:->] {
            out.append(f"{it.tag}@{e.day}");
        }
    }
    return sorted(out);
}

impl transfer(src: str, dst: str) -> int {
    a = station_named(src);
    b = station_named(dst);
    moving = [it for it in [a ->:Holds:->] if not it.is_claimed()];
    for it in moving {
        del [edge it <-:Holds:<-];
        b +>:Holds():+> it;
    }
    return len(moving);
}

impl held_at(station: str) -> list[str] {
    st = station_named(station);
    return sorted([it.tag for it in [st ->:Holds:->] if not it.is_claimed()]);
}

impl expire(today: int, keep_days: int) -> list[str] {
    w = root spawn Expiry(today=today, keep_days=keep_days);
    gone = sorted([it.tag for it in w.stale]);
    for it in w.stale {
        del it;
    }
    return gone;
}
