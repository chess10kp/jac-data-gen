"""FinancialProfileBuilder walker — builds income/asset profile from financial accounts."""

import from graph.nodes.patient { Patient }
import from graph.nodes.financial_account { FinancialAccount }
import from graph.nodes.transaction { Transaction }

walker FinancialProfileBuilder {
    has profile: dict = {};

    can build with Patient entry {
        accounts = [n for n in [here-->] if isinstance(n, FinancialAccount)];
        total_balance: float = 0.0;
        monthly_income: float = 0.0;
        monthly_expenses: float = 0.0;

        for acct in accounts {
            total_balance += getattr(acct, "current_balance", 0.0);
            for txn in [acct-->] {
                if isinstance(txn, Transaction) {
                    if txn.amount > 0 {
                        monthly_income += txn.amount;
                    } else {
                        monthly_expenses += abs(txn.amount);
                    }
                }
            }
        }

        self.profile = {
            "estimated_assets": total_balance,
            "estimated_monthly_income": monthly_income / 12.0 if monthly_income > 0 else 0.0,
            "estimated_monthly_expenses": monthly_expenses / 12.0 if monthly_expenses > 0 else 0.0,
            "has_medicare": here.medicare_id != "",
            "has_medicaid": here.medicaid_id != "",
            "state": here.state
        };

        report self.profile;
    }
}
