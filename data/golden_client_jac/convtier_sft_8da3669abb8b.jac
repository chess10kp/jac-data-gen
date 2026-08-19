node Waypoint {}
edge Leg { has label: str; }

walker LabelTrail {
    has parts: list = [];
    can note with Leg entry { self.parts.append(here.label); }
    can advance with Waypoint entry { visit [edge -->]; }
}

def route_labels(spec: dict) -> str {
    labels: list = list(spec["labels"]);
    pts: list = [Waypoint() for _ in range(len(labels) + 1)];
    for (i, lb) in enumerate(labels) {
        pts[i] +>:Leg(label=str(lb)):+> pts[i + 1];
    }
    return "-".join((pts[0] spawn LabelTrail()).parts);
}

with entry {
    print(route_labels({'labels': ['M1', 'A5']}));
}
