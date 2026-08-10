glob STOCK_RATE = 0;
glob BOND_RATE = 1;
glob STOCK_PCT = 2;

"""Takes in a single year's data during a single simulation and updates the balance."""
def update_balance(
    iteration_balance: float,
    contribution: float,
    current_year_tuple: tuple[float, float, float]
) -> float {
    iteration_balance = iteration_balance + contribution;
    stock_balance = iteration_balance * current_year_tuple[STOCK_PCT];
    bond_balance = iteration_balance * (1 - current_year_tuple[STOCK_PCT]);
    stock_balance += stock_balance * current_year_tuple[STOCK_RATE];
    bond_balance += bond_balance * current_year_tuple[BOND_RATE];
    iteration_balance = stock_balance + bond_balance;
    return iteration_balance;
}