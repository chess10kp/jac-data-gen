"""Club chess ladder: rank 1 is the top. Players challenge up to three rungs above them.

Player nodes hang off root; every recorded match is a Played edge from challenger to defender.
Bodies live in ladder.impl.jac.
"""

enum Outcome {
    WIN = "win",
    LOSS = "loss",
    DRAW = "draw"
}

node Player {
    has name: str;
    has rank: int;
}

"""outcome is from the challenger's side."""
edge Played: Player --> Player {
    has outcome: Outcome;
    has round: int;
}

"""Validate a challenge from root, record it and shift ranks on a win."""
walker RecordChallenge {
    has challenger: str;
    has defender: str;
    has outcome: Outcome;
    has round: int;
    has result: str = "";

    can record with Root entry;
}

"""Spawned on a Player: wins / losses / draws over its matches (optionally vs one opponent)."""
walker Tally {
    has against: str = "";
    has wins: int = 0;
    has losses: int = 0;
    has draws: int = 0;

    can count with Player entry;
    def add(o: Outcome, as_challenger: bool);
}

"""Collect players with a match in round `since` or later."""
walker Activity {
    has since: int;
    has names: list[str] = [];

    can start with Root entry;
    can check with Player entry;
}

def find_player(name: str) -> Player | None;
def join(name: str) -> int;
def standings -> list[str];
def challenge(challenger: str, defender: str, outcome: str, round: int) -> str;
def record(name: str) -> list[int];
def head_to_head(a: str, b: str) -> list[int];
def withdraw(name: str) -> bool;
def active_since(round: int) -> list[str];
