"""Implementations for orchard.jac."""

impl mature_kg(v: Variety) -> float {
    match v {
        case Variety.GALA:
            return 40.0;
        case Variety.FUJI:
            return 50.0;
        case Variety.BRAEBURN:
            return 35.0;
        case _:
            return 30.0;
    }
}

impl parse_variety(name: str) -> Variety | None {
    match name {
        case "gala":
            return Variety.GALA;
        case "fuji":
            return Variety.FUJI;
        case "braeburn":
            return Variety.BRAEBURN;
        case "honeycrisp":
            return Variety.HONEYCRISP;
        case _:
            return None;
    }
}

impl age_factor(age: int) -> float {
    if age < 3 {
        return 0.0;
    }
    if age < 6 {
        return 0.5;
    }
    if age <= 20 {
        return 1.0;
    }
    return 0.75;
}

impl Harvest.on_block {
    visit [here ->:HasRow:->];
}

impl Harvest.on_row {
    self.rows[here.number] = 0;
    visit [here ->:Planted:->];
}

impl Harvest.on_tree {
    if here.sick {
        return;
    }
    for r in [here <-:Planted:<-] {
        self.rows[r.number] += 1;
    }
    name = here.variety.value;
    self.kg[name] = self.kg.get(name, 0.0) + mature_kg(here.variety) * age_factor(here.age);
}

impl NextSeason.on_orchard {
    visit [here -->[?:Block]];
}

impl NextSeason.on_block {
    visit [here ->:HasRow:->];
}

impl NextSeason.on_row {
    visit [here ->:Planted:->];
}

impl NextSeason.on_tree {
    here.age += 1;
}

impl Locate.on_orchard {
    visit [here -->[?:Block]];
}

impl Locate.on_block {
    visit [here ->:HasRow:->];
}

impl Locate.on_row {
    wanted = self.tag;
    hits = [t for t in [here ->:Planted:->] if t.tag == wanted];
    if hits {
        self.found = hits[0];
        disengage;
    }
}

impl Orchard.block(block: str) -> Block | None {
    wanted = block;
    found = [self -->[?:Block, name == wanted]];
    return found[0] if found else None;
}

impl Orchard.add_block(block: str) -> bool {
    if self.block(block) is not None {
        return False;
    }
    self ++> Block(name=block);
    return True;
}

impl Orchard.plant(block: str, row: int, slot: int, tag: str, variety: str, age: int) -> bool {
    b = self.block(block);
    v = parse_variety(variety);
    if b is None or v is None {
        return False;
    }
    if (self spawn Locate(tag=tag)).found is not None or self.tree_at(block, row, slot) != "" {
        return False;
    }
    rows = [x for x in [b ->:HasRow:->] if x.number == row];
    r = rows[0] if rows else None;
    if r is None {
        r = Row(number=row);
        b +>:HasRow():+> r;
    }
    r +>:Planted(slot=slot):+> Tree(tag=tag, variety=v, age=age);
    return True;
}

impl Orchard.tree_at(block: str, row: int, slot: int) -> str {
    b = self.block(block);
    if b is None {
        return "";
    }
    wanted = slot;
    for r in [b ->:HasRow:->] {
        if r.number == row {
            hits = [r ->:Planted:slot == wanted:->];
            if hits {
                return hits[0].tag;
            }
        }
    }
    return "";
}

impl Orchard.mark_diseased(tag: str) -> bool {
    t = (self spawn Locate(tag=tag)).found;
    if t is None {
        return False;
    }
    t.sick = True;
    return True;
}

impl Orchard.next_season {
    self spawn NextSeason();
}

impl Orchard.forecast(block: str) -> float {
    b = self.block(block);
    if b is None {
        return 0.0;
    }
    return sum((b spawn Harvest()).kg.values(), 0.0);
}

impl Orchard.variety_totals(block: str) -> list[str] {
    b = self.block(block);
    if b is None {
        return [];
    }
    kg = (b spawn Harvest()).kg;
    return [f"{v} {kg[v]:.1f}" for v in sorted(kg.keys())];
}

impl Orchard.healthy_rows(block: str) -> list[int] {
    b = self.block(block);
    if b is None {
        return [];
    }
    rows = (b spawn Harvest()).rows;
    return [rows[n] for n in sorted(rows.keys())];
}
