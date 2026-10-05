import from models { FinanceRoot }
import from agents { CreateFinancialGraph, RiskAnalyzer, FutureSimulator }

with entry {

    froot = FinanceRoot();

    froot spawn CreateFinancialGraph();

    print("===== GRAPH CREATED =====");

    risk_result = froot spawn RiskAnalyzer();

    print(risk_result);

    sim_result = froot spawn FutureSimulator();

    print(sim_result);
}