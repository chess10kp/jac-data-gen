"""Recipe scaling and unit conversion helpers."""

obj Ingredient {
    has name: str;
    has qty: float;
    has unit: str;
}

glob VOLUME: dict[str, float] = {"tsp": 5.0, "tbsp": 15.0, "cup": 240.0, "ml": 1.0, "l": 1000.0};
glob WEIGHT: dict[str, float] = {"g": 1.0, "kg": 1000.0, "oz": 28.35};
glob VOLUME_TIDY: list[str] = ["l", "cup", "tbsp", "tsp", "ml"];
glob WEIGHT_TIDY: list[str] = ["kg", "g"];

def scale_recipe(items: list[Ingredient], from_servings: int, to_servings: int) -> list[Ingredient] {
    if from_servings <= 0 or to_servings <= 0 {
        raise ValueError("servings must be positive");
    }
    factor = to_servings / from_servings;
    return [Ingredient(name=i.name, qty=i.qty * factor, unit=i.unit) for i in items];
}

def family(unit: str) -> dict[str, float] | None {
    if unit in VOLUME {
        return VOLUME;
    }
    if unit in WEIGHT {
        return WEIGHT;
    }
    return None;
}

def convert(qty: float, from_unit: str, to_unit: str) -> float {
    src = family(from_unit);
    dst = family(to_unit);
    if src is None or dst is None or src is not dst {
        raise ValueError(f"cannot convert {from_unit} to {to_unit}");
    }
    return qty * src[from_unit] / dst[to_unit];
}

def tidy(item: Ingredient) -> Ingredient {
    fam = family(item.unit);
    if fam is None {
        return Ingredient(name=item.name, qty=item.qty, unit=item.unit);
    }
    order = VOLUME_TIDY if fam is VOLUME else WEIGHT_TIDY;
    base = item.qty * fam[item.unit];
    for u in order {
        q = base / fam[u];
        if q >= 1 - 1e-9 {
            return Ingredient(name=item.name, qty=q, unit=u);
        }
    }
    return Ingredient(name=item.name, qty=item.qty, unit=item.unit);
}
