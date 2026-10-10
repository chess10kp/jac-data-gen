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
    has checked: int = 0;
    has flagged: list[str] = [];

    can start with Root entry {
        visit [-->[?:Hive]];
    }

    can inspect with Hive entry {
        self.checked += 1;
        queenless_and_weak = not here.queen_seen and here.brood_frames < 3;
        if queenless_and_weak or here.temper >= 4 {
            self.flagged.append(here.tag);
        }
    }

    can finish with Root exit {
        report sorted(self.flagged);
    }
}
