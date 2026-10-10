impl Standings.scan {
    if self.track {
        visit [-->[?:Track, name == self.track]];
    } else {
        visit [-->[?:Track]];
    }
}

impl Standings.enter_track {
    visit [here ->:Entered:->];
}

impl Standings.collect {
    self.teams.append(here);
}

impl Backlog.start {
    self.me = here;
    visit [here ->:Covers:->];
}

impl Backlog.enter_track {
    visit [here ->:Entered:->];
}

impl Backlog.check {
    j = self.me;
    if j is not None and len(j.sheet_for(here)) < 3 {
        self.todo.append(here.name);
    }
}
