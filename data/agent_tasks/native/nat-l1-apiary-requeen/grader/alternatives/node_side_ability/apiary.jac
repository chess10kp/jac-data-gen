"""Apiary records: one Hive node per colony, attached to root."""

node Hive {
    has tag: str;
    has brood_frames: int = 0;
    has queen_seen: bool = True;
    has temper: int = 1;   # 1 = calm ... 5 = very aggressive

    def needs_requeen -> bool {
        if self.temper >= 4 {
            return True;
        }
        return (not self.queen_seen) and self.brood_frames < 3;
    }

    can audited_by with RequeenAudit entry {
        visitor.checked += 1;
        if self.needs_requeen() {
            visitor.flagged.append(self.tag);
        }
    }
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

    can finish with Root exit {
        self.flagged.sort();
        report self.flagged;
    }
}
