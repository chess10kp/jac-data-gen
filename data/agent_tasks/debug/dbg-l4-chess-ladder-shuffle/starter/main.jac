"""Season demo: replays a few challenges and prints the ladder."""
import from ladder { join }
import from challenge { RecordMatch, Standings, HeadToHead }

with entry {
    for n in ["Ada", "Ben", "Cyd", "Dov", "Eli"] {
        join(n);
    }
    root spawn RecordMatch(challenger="Eli", defender="Ben", challenger_won=True, round=1);
    root spawn RecordMatch(challenger="Dov", defender="Cyd", challenger_won=False, round=1);
    bad = root spawn RecordMatch(challenger="Dov", defender="Ada", challenger_won=True, round=2);
    print("rejected: " + bad.reports[0].reason);
    s = root spawn Standings();
    print("ladder: " + " > ".join(s.reports[0]));
    h = root spawn HeadToHead(a="Dov", b="Cyd");
    print("dov-cyd: " + str(h.reports[0]["Dov"]) + "-" + str(h.reports[0]["Cyd"]));
}
