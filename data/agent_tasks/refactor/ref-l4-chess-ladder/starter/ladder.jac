"""Club chess ladder: rank 1 is the top. Players challenge up to three rungs above them."""

node LadderBook {
    has ranks: dict[str, int] = {};
    has matches: list[dict[str, any]] = [];
}

def _book -> LadderBook {
    for n in [root -->] {
        if isinstance(n, LadderBook) {
            return n;
        }
    }
    b = LadderBook();
    root ++> b;
    return b;
}

"""Add a player at the bottom; returns their rank, or 0 if already on the ladder."""
def join(name: str) -> int {
    b = _book();
    if name in b.ranks {
        return 0;
    }
    b.ranks[name] = len(b.ranks) + 1;
    return b.ranks[name];
}

def standings -> list[str] {
    b = _book();
    out: list[str] = ["" for n in b.ranks];
    for n in b.ranks {
        out[b.ranks[n] - 1] = n;
    }
    return out;
}

"""Record a challenge. outcome is from the challenger's side: "win", "loss" or "draw"."""
def challenge(challenger: str, defender: str, outcome: str, round: int) -> str {
    b = _book();
    if challenger not in b.ranks or defender not in b.ranks or challenger == defender {
        return "unknown player";
    }
    if outcome != "win" and outcome != "loss" and outcome != "draw" {
        return "bad outcome";
    }
    gap = b.ranks[challenger] - b.ranks[defender];
    if gap <= 0 or gap > 3 {
        return "out of range";
    }
    b.matches.append({"challenger": challenger, "defender": defender, "outcome": outcome, "round": round});
    if outcome == "win" {
        old_c = b.ranks[challenger];
        old_d = b.ranks[defender];
        for n in b.ranks {
            if b.ranks[n] >= old_d and b.ranks[n] < old_c {
                b.ranks[n] = b.ranks[n] + 1;
            }
        }
        b.ranks[challenger] = old_d;
    }
    return "ok";
}

"""[wins, losses, draws] for a player over every match they played, as either side."""
def record(name: str) -> list[int] {
    b = _book();
    out = [0, 0, 0];
    for m in b.matches {
        if m["challenger"] == name {
            if m["outcome"] == "win" {
                out[0] += 1;
            } elif m["outcome"] == "loss" {
                out[1] += 1;
            } else {
                out[2] += 1;
            }
        } elif m["defender"] == name {
            if m["outcome"] == "win" {
                out[1] += 1;
            } elif m["outcome"] == "loss" {
                out[0] += 1;
            } else {
                out[2] += 1;
            }
        }
    }
    return out;
}

"""[wins for a, wins for b, draws] over the matches between a and b."""
def head_to_head(a: str, b: str) -> list[int] {
    bk = _book();
    out = [0, 0, 0];
    for m in bk.matches {
        pair = [m["challenger"], m["defender"]];
        if not (pair == [a, b] or pair == [b, a]) {
            continue;
        }
        if m["outcome"] == "draw" {
            out[2] += 1;
        } elif (m["outcome"] == "win") == (m["challenger"] == a) {
            out[0] += 1;
        } else {
            out[1] += 1;
        }
    }
    return out;
}

"""Remove a player and their match history; everyone below moves up one rung."""
def withdraw(name: str) -> bool {
    b = _book();
    if name not in b.ranks {
        return False;
    }
    gone = b.ranks[name];
    b.ranks.pop(name);
    for n in b.ranks {
        if b.ranks[n] > gone {
            b.ranks[n] = b.ranks[n] - 1;
        }
    }
    keep: list[dict[str, any]] = [];
    for m in b.matches {
        if m["challenger"] != name and m["defender"] != name {
            keep.append(m);
        }
    }
    b.matches = keep;
    return True;
}

"""Players whose last recorded match was in the given round or later."""
def active_since(round: int) -> list[str] {
    b = _book();
    out: list[str] = [];
    for m in b.matches {
        if m["round"] >= round {
            for who in [m["challenger"], m["defender"]] {
                if who not in out {
                    out.append(who);
                }
            }
        }
    }
    return sorted(out);
}
