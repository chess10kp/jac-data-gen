"""Apiary colony status: active -> queenless -> requeened, or lost at any point."""

enum HiveStatus {
    ACTIVE = "active",
    QUEENLESS = "queenless",
    REQUEENED = "requeened",
    LOST = "lost"
}

obj Hive {
    has tag: str;
    has brood_frames: int = 0;
    has status: HiveStatus = HiveStatus.ACTIVE;

    def has_queen -> bool {
        return self.status in [HiveStatus.ACTIVE, HiveStatus.REQUEENED];
    }
}

def mark_queenless(hive: Hive) -> bool {
    if hive.has_queen() {
        hive.status = HiveStatus.QUEENLESS;
        return True;
    }
    return False;
}

def requeen(hive: Hive) -> bool {
    if hive.status == HiveStatus.QUEENLESS {
        hive.status = HiveStatus.REQUEENED;
        return True;
    }
    return False;
}

def record_loss(hive: Hive) -> bool {
    if hive.status != HiveStatus.LOST {
        hive.status = HiveStatus.LOST;
        return True;
    }
    return False;
}

def hive_label(hive: Hive) -> str {
    return f"{hive.tag}: {hive.status.value}";
}

def needs_visit(hives: list[Hive]) -> list[str] {
    return sorted([
        h.tag for h in hives
        if h.status == HiveStatus.QUEENLESS or (h.has_queen() and h.brood_frames < 3)
    ]);
}
