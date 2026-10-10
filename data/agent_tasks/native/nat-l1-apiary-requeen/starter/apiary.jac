"""Apiary records: one Hive node per colony, attached to root."""

node Hive {
    has tag: str;
    has brood_frames: int = 0;
    has queen_seen: bool = True;
    has temper: int = 1;   # 1 = calm ... 5 = very aggressive
}

def add_hive(tag: str, brood_frames: int, queen_seen: bool, temper: int) -> Hive {
    return root ++> Hive(tag=tag, brood_frames=brood_frames, queen_seen=queen_seen, temper=temper);
}

walker RequeenAudit {
    # TODO: walk the hives on root and report which ones need a new queen.
    can start with Root entry {
    }
}
