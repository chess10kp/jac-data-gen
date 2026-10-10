"""Parcel shipping quotes."""

import math;

glob RATES: dict[str, tuple[float, float]] = {
    "domestic": (5.0, 1.2),
    "regional": (9.0, 2.0),
    "international": (20.0, 4.5)
};

def billable_weight(actual_kg: float, length_cm: float, width_cm: float, height_cm: float) -> float {
    if min(actual_kg, length_cm, width_cm, height_cm) <= 0 {
        raise ValueError("dimensions and weight must be positive");
    }
    volumetric = length_cm * width_cm * height_cm / 5000;
    w = max(actual_kg, volumetric);
    return math.ceil(round(w * 2, 9)) / 2;
}

def quote(weight_kg: float, zone: str) -> float {
    if zone not in RATES {
        raise ValueError(f"unknown zone {zone}");
    }
    if weight_kg <= 0 {
        raise ValueError("weight must be positive");
    }
    (base, per_kg) = RATES[zone];
    return round(base + max(0.0, weight_kg - 1) * per_kg, 2);
}

def free_shipping(order_total: float, zone: str) -> bool {
    if zone == "domestic" {
        return order_total >= 50;
    }
    if zone == "regional" {
        return order_total >= 100;
    }
    if zone == "international" {
        return False;
    }
    raise ValueError(f"unknown zone {zone}");
}
