"""Lunch poll: Poll nodes with a Ballot edge per voter carrying their choice."""

node Poll {
    has name: str;
}

node Voter {
    has name: str;
}

edge Ballot: Voter --> Poll {
    has choice: str;
}

walker:pub cast_vote {
    has poll: str;
    has voter: str;
    has choice: str;

    can vote with Root entry {
        polls = [p for p in [here -->[?:Poll]] if p.name == self.poll];
        p = polls[0] if polls else here ++> Poll(name=self.poll);
        voters = [v for v in [here -->[?:Voter]] if v.name == self.voter];
        v = voters[0] if voters else here ++> Voter(name=self.voter);
        del [edge v ->:Ballot:-> p];
        v +>:Ballot(choice=self.choice.strip().lower()):+> p;
        tallies: dict[str, int] = {};
        for b in [edge p <-:Ballot:<-] {
            tallies[b.choice] = tallies.get(b.choice, 0) + 1;
        }
        leader = sorted(tallies.items(), key=lambda (kv: tuple[str, int]) -> tuple[int, str] { return (-kv[1], kv[0]); })[0][0];
        report {"poll": p.name, "tallies": tallies, "leader": leader};
    }
}
