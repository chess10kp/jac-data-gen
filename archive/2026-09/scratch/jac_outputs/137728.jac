"""Check that every player does not come in 1st and does not come in last
    at least once each."""
def check_games(games: Any) -> object {
    pc = `dict();
    for game in games {
        max_rank = 0;
        max_user = None;
        for (user, rank) in game.items() {
            if (rank > 1) {
                pc.setdefault(user, [1, 1])[1] = 0;
            }
            if (rank > max_rank) {
                if max_user {
                    pc.setdefault(max_user, [1, 1])[0] = 0;
                }
                max_rank = rank;
                max_user = user;
            } elif (rank < max_rank) {
                pc.setdefault(user, [1, 1])[0] = 0;
            }
        }
    }
    missing_wl = sum((w + l) for (w, l) in pc.values());
    if (missing_wl > 0) {
        winners = `list();
        losers = `list();
        for (player, (win, loss)) in pc.items() {
            if (not win and not loss) {
                continue;
            }
            if (win and loss) {
                raise Exception(("Player with neither win or loss %s" % (player, )));
            }
            if win {
                losers.append(player);
            } else {
                winners.append(player);
            }
            print(("Player %s has no %s" % (player, "win" if win else "loss")));
        }
        return (winners, losers);
    }
    return (None, None);
}