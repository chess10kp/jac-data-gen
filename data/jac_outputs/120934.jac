"""
    Pick a target $-amount you want to win. and then make a sequence of bets that follows the ratio output below.

    Each wager must be at odds such that the profit (payout) is the sum of the first and last number in your list.
    If bet 1 wins 20 (.1 + .1) then cross off the first and last numbers.

    If you lose add your stake to the list below.

    :param target: Integer. How much do you want to win?
    :return: List. Sequence of $ amount bets to make.
    """
def five_bet_labouchere_bankroll(target: Any) -> object {
    labouchere_div = [0.1, 0.2, 0.4, 0.2, 0.1];
    return [(target * x) for x in labouchere_div];
}