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
