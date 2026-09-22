""" Basic Shares calculator"""
def calc_share_ratios(list_prio: list[list[float]], cores: int) -> list[float] | None {
    max_shares_per_app = 100;
    shares_per_app: list[float] | None = None;
    if len(list_prio) <= cores {
        total_shares = sum([r[2] for r in list_prio]);
        shares_per_app = [r[2] / total_shares for r in list_prio];
        print(total_shares, shares_per_app);
    } elif len(list_prio) > cores {
        shares_per_app = [max_shares_per_app / (max_shares_per_app * cores)] * cores;
    }
    return shares_per_app;
}