"""Alumni mentorship network: typed edge creation with data.

Mentorship links are Mentor edges carrying the year they started.
Building them with `+>: Mentor(year=...) :+>` keeps the relationship
data on the edge itself, and a query walker filters on that data
while traversing.
"""

node Alumnus {
    has name: str = "";
    has grad_year: int = 0;
}

edge Mentor: Alumnus --> Alumnus {
    has since_year: int = 0;
}

walker MenteeFinder {
    has min_year: int = 2015;
    has found: list[str] = [];

    can start with Root entry {
        visit [-->];
    }

    can seek with Alumnus entry {
        mentees = [->:Mentor:since_year >= self.min_year:->];
        for m in mentees {
            self.found.append(m.name);
            print(f"{here.name} mentored {m.name} from {self.min_year} onward");
        }
        visit [-->];
    }
}

with entry {
    dana = Alumnus(name="Dana", grad_year=2005);
    eli = Alumnus(name="Eli", grad_year=2016);
    fatima = Alumnus(name="Fatima", grad_year=2018);
    gus = Alumnus(name="Gus", grad_year=2021);

    root ++> dana;
    dana +>: Mentor(since_year=2017) :+> eli;
    eli +>: Mentor(since_year=2019) :+> fatima;
    fatima +>: Mentor(since_year=2022) :+> gus;

    result = root spawn MenteeFinder(min_year=2018);
    print(f"Mentorships since 2018: {result.found}");
}
