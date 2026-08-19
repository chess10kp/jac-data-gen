obj Member {
    has name: str = "";
    has points: int = 0;

    def tier -> str {
        if self.points >= 100 {
            return "gold";
        } elif self.points >= 50 {
            return "silver";
        }
        return "bronze";
    }
}

def badge_label(user: dict) -> str {
    m = Member(name=user["name"], points=user.get("points", 0));
    return f"{m.name} [{m.tier()}]";
}

with entry {
    print(badge_label({'name': 'Ana', 'points': 120}));
}
