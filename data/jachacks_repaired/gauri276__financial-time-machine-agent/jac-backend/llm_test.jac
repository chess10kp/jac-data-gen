import from llm_agents { FinancialAdvisor }

with entry {

    advisor = FinancialAdvisor(
        financial_summary =
        "Monthly Income: 45000, Monthly Surplus: 11000, Goal ETA: 9 months, Emergency Coverage: 1 month, Risk Level: Risky"
    );

    result = root spawn advisor;

    print(result);
}
