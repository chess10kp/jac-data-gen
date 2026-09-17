# Lifting samarthify/UniSummary#1 (DSA roadmap: prerequisite topic graph,
# recursive DFS / BFS traversal, manual adjacency machinery) to idiomatic Jac OSP.

node Topic {
    has name: str;
    has tag: str = "core";
    has done: bool = False;
}

edge PREREQ {}

obj Catalog {
    has topics: dict[str, Topic] = {};

    # register a study topic; unknown-tolerance lives at the string-API layer
    def add_topic(name: str, tag: str = "core") -> Topic {
        t = Topic(name=name, tag=tag);
        self.topics[name] = t;
        root ++> t;
        return t;
    }

    # b must be studied before a; both ids must resolve
    def link_prereq(a: str, b: str) -> bool {
        if a not in self.topics or b not in self.topics {
            return False;
        }
        ta = self.topics[b];
        tb = self.topics[a];
        ta +>:PREREQ:+> tb;
        return True;
    }

    # mark everything reachable (a and its full prerequisite closure) done
    def complete(start: str) -> list[str] {
        if start not in self.topics {
            return [];
        }
        st = self.topics[start];
        w = st spawn Closer(claimed={}, order=[]);
        return w.order;
    }

    # breadth-first study plan (level by level)
    def study_plan_bfs(start: str) -> list[str] {
        if start not in self.topics {
            return [];
        }
        st = self.topics[start];
        w = st spawn PlanBFS(claimed={}, order=[]);
        return w.order;
    }

    # depth-first plan visiting prerequisites in sorted-name order
    def study_plan_dfs(start: str) -> list[str] {
        if start not in self.topics {
            return [];
        }
        st = self.topics[start];
        w = st spawn PlanDFS(claimed={}, order=[], topics=self.topics);
        return w.order;
    }

    # count connected study groups over an id subset (unknown ids ignored)
    def group_count(ids: list[str]) -> int {
        seen: dict[str, bool] = {};
        groups = 0;
        for i in sorted(ids) {
            if i not in self.topics or i in seen {
                continue;
            }
            st = self.topics[i];
            w = st spawn Closer(claimed={}, order=[]);
            groups += 1;
            for nm in w.order {
                seen[nm] = True;
            }
        }
        return groups;
    }
}

# closure walker: claim-map + skip is the ONLY cycle policy
walker Closer {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Topic entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        here.done = True;
        self.order.append(here.name);
        visit [here ->:PREREQ:->];
    }
}

# BFS plan: default visit order (frontier queue)
walker PlanBFS {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];

    can step with Topic entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        visit [here ->:PREREQ:->];
    }
}

# DFS plan: front-inserted, name-sorted child visits (no lambda, no comprehension)
walker PlanDFS {
    has claimed: dict[str, bool] = {};
    has order: list[str] = [];
    has topics: dict[str, Topic] = {};

    can step with Topic entry {
        if here.name in self.claimed {
            skip;
        }
        self.claimed[here.name] = True;
        self.order.append(here.name);
        targets: list[Topic] = [here ->:PREREQ:->][?:Topic];
        names: list[str] = [];
        for t in targets {
            names.append(t.name);
        }
        names = sorted(names);
        kids: list[Topic] = [];
        for nm in names {
            kids.append(self.topics[nm]);
        }
        visit :0: kids;
    }
}

with entry {
    cat = Catalog();
    dp = cat.add_topic("DynamicProgramming", "hard");
    cat.add_topic("Arrays", "easy");
    cat.add_topic("Trees", "medium");
    cat.add_topic("Graphs", "medium");
    cat.link_prereq("DynamicProgramming", "Arrays");
    cat.link_prereq("DynamicProgramming", "Trees");
    cat.link_prereq("Trees", "Arrays");
    cat.link_prereq("Graphs", "Trees");
    wk = root spawn Closer(claimed={}, order=[]);
    print(wk.order);
    print(cat.study_plan_bfs("DynamicProgramming"));
    print(cat.study_plan_dfs("DynamicProgramming"));
    print(cat.group_count(["DynamicProgramming", "Graphs", "nope"]));
}

test "diamond revisit is visited once" {
    cat = Catalog();
    cat.add_topic("A");
    cat.add_topic("B");
    cat.add_topic("C");
    cat.add_topic("D");
    cat.link_prereq("B", "A");
    cat.link_prereq("C", "A");
    cat.link_prereq("D", "B");
    cat.link_prereq("D", "C");
    got = cat.complete("D");
    assert len(got) == 4;
    assert sorted(got) == ["A", "B", "C", "D"];
}

test "unknown id tolerated with empty result" {
    cat = Catalog();
    cat.add_topic("Solo");
    assert cat.complete("Ghost") == [];
    assert cat.study_plan_bfs("Ghost") == [];
    assert cat.study_plan_dfs("Ghost") == [];
    assert cat.link_prereq("Solo", "Ghost") == False;
}

test "bfs vs dfs same closure different order" {
    cat = Catalog();
    cat.add_topic("Arrays");
    cat.add_topic("Trees");
    cat.add_topic("Graphs");
    cat.link_prereq("Graphs", "Arrays");
    cat.link_prereq("Graphs", "Trees");
    b = cat.study_plan_bfs("Graphs");
    d = cat.study_plan_dfs("Graphs");
    assert b[0] == "Graphs" and d[0] == "Graphs";
    assert sorted(b) == sorted(d);
    assert len(b) == 3 and len(d) == 3;
}

test "group count ignores unknown and merges components" {
    cat = Catalog();
    cat.add_topic("X");
    cat.add_topic("Y");
    cat.add_topic("Z");
    cat.link_prereq("Y", "X");
    assert cat.group_count(["X", "Y", "Z", "Q"]) == 2;
    assert cat.group_count([]) == 0;
}

test "cycle safe closure via claim map" {
    cat = Catalog();
    cat.add_topic("M");
    cat.add_topic("N");
    cat.link_prereq("M", "N");
    cat.link_prereq("N", "M");
    got = cat.complete("M");
    assert sorted(got) == ["M", "N"];
}
