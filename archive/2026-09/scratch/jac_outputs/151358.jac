"""Brute force solution expecting an ideal dataset with one and only one pair."""
def fix_expense_report(list_of_expenses: list[int]) -> int | None {
    for i in range(len(list_of_expenses)) {
        for j in range(i, len(list_of_expenses)) {
            summ = list_of_expenses[i] + list_of_expenses[j];
            if summ == 2020 {
                print(list_of_expenses[i], list_of_expenses[j]);
                return list_of_expenses[i] * list_of_expenses[j];
            }
        }
    }
}