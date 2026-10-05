"""You are a financial AI advisor. Analyze this financial situation and provide risk analysis, spending insights, emergency fund analysis, and financial recovery suggestions."""
def advise_finances(financial_summary: str) -> str by llm();

walker FinancialAdvisor {

    has financial_summary: str;

    can advise with entry {

        response = advise_finances(self.financial_summary);

        report response;
    }
}
