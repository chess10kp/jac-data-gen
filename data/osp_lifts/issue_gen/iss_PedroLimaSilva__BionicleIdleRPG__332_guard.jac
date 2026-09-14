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

test "diamond revisit is not a cycle" {
    root_quest = Quest(id="root", unlocked_after=["left", "right"]);
    left = Quest(id="left", unlocked_after=["shared"]);
    right = Quest(id="right", unlocked_after=["shared"]);
    shared = Quest(id="shared", unlocked_after=["deep"]);
    deep = Quest(id="deep");
    assert(detectQuestCycles([root_quest, left, right, shared, deep]) == []);
}

test "unknown prerequisite ids are ignored" {
    quest = Quest(id="solo", unlocked_after=["missing"]);
    assert(detectQuestCycles([quest]) == []);
}

test "self dependency is reported" {
    quest = Quest(id="solo", unlocked_after=["solo"]);
    assert(detectQuestCycles([quest]) == ["solo"]);
}

test "multi node cycle returns sorted ids" {
    alpha = Quest(id="alpha", unlocked_after=["charlie"]);
    bravo = Quest(id="bravo", unlocked_after=["alpha"]);
    charlie = Quest(id="charlie", unlocked_after=["bravo"]);
    assert(detectQuestCycles([charlie, alpha, bravo]) == ["alpha", "bravo", "charlie"]);
}

test "empty quest collection has no cycles" {
    assert(detectQuestCycles([]) == []);
}
