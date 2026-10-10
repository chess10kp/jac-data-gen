"""Match history types. A Played edge points from challenger to defender."""
import from ladder { Player }

edge Played: Player --> Player {
    has challenger_won: bool;
    has round: int;
}

obj MatchResult {
    has ok: bool;
    has reason: str = "";
    has new_rank: int = 0;
}
