glob company_info = """
Company: TechCorp
Products: CloudDB, SecureAuth, DataViz
Support Hours: 9 AM - 5 PM EST
""";

def support_agent(question: str) -> str by llm(
    incl_info={"company_context": company_info}
);
sem support_agent = "Answer customer questions about our products and services.";
