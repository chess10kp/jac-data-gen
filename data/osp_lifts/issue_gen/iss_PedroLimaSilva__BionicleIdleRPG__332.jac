# PedroLimaSilva/BionicleIdleRPG#332

node Quest {
    has id: str;
    has unlocked_after: list[str] = [];
}

edge Unlocks {}

walker QuestCycleProbe {
    has origin_id: str = "";
    has claimed: dict[str, bool] = {};
    has started: bool = False;
    has found: bool = False;

    can probe with Quest entry {
        if self.started {
            if here.id == self.origin_id {
                self.found = True;
                print("cycle:" + here.id);
                skip;
            }
        }
        if here.id in self.claimed {
            skip;
        }
        self.claimed[here.id] = True;
        self.started = True;
        print("visit:" + here.id);
        for prerequisite in [here ->:Unlocks:->][?:Quest] {
            visit :0: [prerequisite];
        }
    }
}

def detectQuestCycles(quests: list[Quest]) -> list[str] {
    for quest in quests {
        for dependency_id in quest.unlocked_after {
            for candidate in quests {
                if candidate.id == dependency_id {
                    quest +>:Unlocks:+> candidate;
                }
            }
        }
    }

    cycles: list[str] = [];
    for quest in quests {
        w = quest spawn QuestCycleProbe(origin_id=quest.id);
        if w.found {
            cycles.append(quest.id);
        }
    }
    return sorted(cycles);
}
