import from models { FinanceRoot, UserProfile, ExpenseCategory, FinancialGoal, Scenario }


walker CreateFinancialGraph {

    can create with FinanceRoot entry {

        user = here ++> UserProfile(
            name="GD",
            monthly_income=45000,
            current_savings=30000
        );

        user[0] ++> ExpenseCategory(
            category_name="Food",
            amount=8000
        );

        user[0] ++> ExpenseCategory(
            category_name="Shopping",
            amount=4000
        );

        user[0] ++> FinancialGoal(
            goal_name="Buy MacBook",
            goal_amount=120000,
            target_months=8
        );

        report "Financial graph created";
    }
}



walker RiskAnalyzer {

    can analyze_root with FinanceRoot entry {

        report "RiskAnalyzer started";

        visit [-->];
    }

    can analyze_user with UserProfile entry {

        if here.current_savings < 50000 {

            report "Emergency savings are low";
        }

        visit [-->];
    }

    can analyze_expense with ExpenseCategory entry {

        if here.amount > 5000 {

            report f"{here.category_name} spending is high";
        }
    }

    can analyze_goal with FinancialGoal entry {

        report f"Goal detected: {here.goal_name}";
    }
}



walker FutureSimulator {

    can simulate_root with FinanceRoot entry {

        report "Future simulation started";

        visit [-->];
    }

    can simulate_user with UserProfile entry {

        if here.monthly_income < 50000 {

            here ++> Scenario(
                scenario_name="Risky Future",
                risk_level="High"
            );

            report "Risky future generated";
        }

        visit [-->];
    }
}