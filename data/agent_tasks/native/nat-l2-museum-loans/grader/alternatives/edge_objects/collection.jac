"""Museum collections: Museum -Owns-> Artwork, Artwork -LoanedTo-> Museum."""

node Museum {
    has name: str;
}

node Artwork {
    has title: str;
    has in_conservation: bool = False;
}

edge Owns: Museum --> Artwork {}

edge LoanedTo: Artwork --> Museum {
    has start_year: int;
    has end_year: int;
}

def acquire(museum: Museum, title: str) -> Artwork {
    art = Artwork(title=title);
    museum +>:Owns():+> art;
    return art;
}

def lend(art: Artwork, borrower: Museum, start_year: int, end_year: int) {
    art +>:LoanedTo(start_year=start_year, end_year=end_year):+> borrower;
}

def active(loan: LoanedTo, year: int) -> bool {
    return loan.start_year <= year and year <= loan.end_year;
}

walker OnDisplay {
    has year: int;
    has shown: int = 0;
    has host: Museum | None = None;
    has titles: list[str] = [];

    can start with Museum entry {
        self.host = here;
        visit [here ->:Owns:->];
        visit [here <-:LoanedTo:<-];
    }

    can judge with Artwork entry {
        if here.in_conservation or here.title in self.titles {
            return;
        }
        live = [l for l in [edge here ->:LoanedTo:->] if active(l, self.year)];
        host = self.host;
        borrowed_here = False;
        owned = False;
        if host is not None {
            borrowed_here = len([l for l in [edge here ->:LoanedTo:-> host] if active(l, self.year)]) > 0;
            owned = here in [host ->:Owns:->];
        }
        if borrowed_here or (owned and len(live) == 0) {
            self.titles.append(here.title);
        }
    }

    can finish with Museum exit {
        self.titles.sort();
        self.shown = len(self.titles);
        report self.titles;
    }
}
