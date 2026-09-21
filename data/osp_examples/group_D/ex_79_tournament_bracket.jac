"""Tournament bracket resolution.

Quarter-finals hold two seeded players each; later rounds are fed through
FeedsInto edges. A judge walker recurses by spawning itself on the two
feeding matches, so each match is resolved only after both of its feeders
have already decided their winners synchronously -- stronger players bubble
up round by round until the champion is crowned.
"""

node Match {
    has round_no: int;
    has label: str;
    has seed_a: str = "";
    has rating_a: float = 0.0;
    has seed_b: str = "";
    has rating_b: float = 0.0;
    has winner: str = "";
    has winner_rating: float = 0.0;
}

edge FeedsInto: Match --> Match {}

walker RoundJudge {
    can judge with Match entry {
        if here.winner != "" {
            skip;  # already decided through another path
        }

        # Judge both feeding matches first (synchronous spawns).
        for feeder in [<-:FeedsInto:<-] {
            feeder spawn RoundJudge();
        }

        # Compare seeds against the winners that bubbled up.
        best_name = here.seed_a;
        best_rating = here.rating_a;
        if here.rating_b > best_rating {
            best_name = here.seed_b;
            best_rating = here.rating_b;
        }
        for feeder in [<-:FeedsInto:<-] {
            if feeder.winner_rating > best_rating {
                best_name = feeder.winner;
                best_rating = feeder.winner_rating;
            }
        }
        here.winner = best_name;
        here.winner_rating = best_rating;

        rating_txt = round(best_rating, 1);
        print(f"{here.label}: {here.winner} wins (rating {rating_txt})");
    }
}

with entry {
    for stale in [root -->][?:Match] {
        del stale;
    }

    qf1 = Match(round_no=1, label="QF1", seed_a="Ana", rating_a=7.2, seed_b="Bea", rating_b=6.8);
    qf2 = Match(round_no=1, label="QF2", seed_a="Cy", rating_a=8.1, seed_b="Dee", rating_b=5.5);
    qf3 = Match(round_no=1, label="QF3", seed_a="Eli", rating_a=6.9, seed_b="Fay", rating_b=7.4);
    qf4 = Match(round_no=1, label="QF4", seed_a="Gus", rating_a=6.3, seed_b="Hal", rating_b=6.1);

    sf1 = Match(round_no=2, label="SF1");
    sf2 = Match(round_no=2, label="SF2");
    final = Match(round_no=3, label="Final");

    qf1 +>: FeedsInto() :+> sf1;
    qf2 +>: FeedsInto() :+> sf1;
    qf3 +>: FeedsInto() :+> sf2;
    qf4 +>: FeedsInto() :+> sf2;
    sf1 +>: FeedsInto() :+> final;
    sf2 +>: FeedsInto() :+> final;

    # Judging starts at the championship and recurses down the bracket.
    final spawn RoundJudge();

    print(f"Champion: {final.winner}");
}
