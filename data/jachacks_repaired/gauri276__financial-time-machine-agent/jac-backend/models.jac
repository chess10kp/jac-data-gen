node FinanceRoot {}

node UserProfile {
    has name: str;
    has monthly_income: int;
    has current_savings: int;
}

node ExpenseCategory {
    has category_name: str;
    has amount: int;
}

node FinancialGoal {
    has goal_name: str;
    has goal_amount: int;
    has target_months: int;
}

node Scenario {
    has scenario_name: str;
    has risk_level: str;
}