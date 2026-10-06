"""Vendor discovery — mock implementation with instant return."""

import from random { randint, sample }


# Fake vendor pool keyed by category
glob _FAKE_VENDORS: dict = {
    "plumbing": [
        {"name": "FlowFix Plumbing Co.", "phone": "+1 416-555-0182", "rating": 4.7, "avg_cost": 175.0},
        {"name": "Aqua Pro Services",    "phone": "+1 416-555-0247", "rating": 4.4, "avg_cost": 140.0},
        {"name": "PipeMaster Toronto",   "phone": "+1 647-555-0391", "rating": 4.2, "avg_cost": 195.0}
    ],
    "electrical": [
        {"name": "Volta Electric Inc.",     "phone": "+1 416-555-0138", "rating": 4.8, "avg_cost": 210.0},
        {"name": "PowerGrid Solutions",     "phone": "+1 647-555-0274", "rating": 4.5, "avg_cost": 185.0},
        {"name": "Spark & Wire Electrical", "phone": "+1 416-555-0356", "rating": 4.3, "avg_cost": 160.0}
    ],
    "hvac": [
        {"name": "AirCare HVAC",        "phone": "+1 416-555-0421", "rating": 4.6, "avg_cost": 230.0},
        {"name": "Climate Control Pro",  "phone": "+1 647-555-0183", "rating": 4.4, "avg_cost": 200.0},
        {"name": "ThermoFix Services",   "phone": "+1 416-555-0509", "rating": 4.1, "avg_cost": 165.0}
    ],
    "appliance": [
        {"name": "AppliancePro Repairs",  "phone": "+1 416-555-0612", "rating": 4.5, "avg_cost": 120.0},
        {"name": "FixIt Fast Appliances", "phone": "+1 647-555-0745", "rating": 4.3, "avg_cost": 100.0},
        {"name": "HomeGear Tech",         "phone": "+1 416-555-0831", "rating": 4.0, "avg_cost": 110.0}
    ],
    "general": [
        {"name": "AllHands Maintenance",  "phone": "+1 416-555-0914", "rating": 4.4, "avg_cost": 130.0},
        {"name": "QuickFix Handyman",     "phone": "+1 647-555-0062", "rating": 4.2, "avg_cost": 110.0},
        {"name": "ProCare Property Svcs", "phone": "+1 416-555-0173", "rating": 4.6, "avg_cost": 150.0}
    ]
};

glob _DEFAULT_NEAR: str = "Toronto, ON";


def fetch_vendors_near(category: str, near: str) -> list {
    key = category.lower();
    pool: any = _FAKE_VENDORS.get(key, _FAKE_VENDORS["general"]);
    count = randint(2, len(pool));
    vendors = [];
    for v in sample(pool, count) {
        vendors.append({
            "name":     v["name"],
            "category": category,
            "phone":    v["phone"],
            "rating":   v["rating"],
            "avg_cost": v["avg_cost"]
        });
    }
    print("[foursquare] returning " + str(len(vendors)) + " mock vendor(s) for '" + category + "'");
    return vendors;
}

