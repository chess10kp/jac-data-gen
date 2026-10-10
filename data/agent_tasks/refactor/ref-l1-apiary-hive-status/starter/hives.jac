"""Apiary colony status: active -> queenless -> requeened, or lost at any point."""

obj Hive {
    has tag: str;
    has brood_frames: int = 0;
    has status: str = "active";
}

def mark_queenless(hive: Hive) -> bool {
    if hive.status == "active" or hive.status == "requeened" {
        hive.status = "queenless";
        return True;
    }
    return False;
}

def requeen(hive: Hive) -> bool {
    if hive.status == "queenless" {
        hive.status = "requeened";
        return True;
    }
    return False;
}

def record_loss(hive: Hive) -> bool {
    if hive.status != "lost" {
        hive.status = "lost";
        return True;
    }
    return False;
}

def hive_label(hive: Hive) -> str {
    return f"{hive.tag}: {hive.status}";
}

def needs_visit(hives: list[Hive]) -> list[str] {
    out: list[str] = [];
    for h in hives {
        if h.status == "queenless" {
            out.append(h.tag);
        } elif (h.status == "active" or h.status == "requeened") and h.brood_frames < 3 {
            out.append(h.tag);
        }
    }
    return sorted(out);
}
