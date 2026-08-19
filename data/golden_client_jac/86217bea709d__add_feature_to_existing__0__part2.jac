glob company_info = """
Company: TechCorp
Products: CloudDB, SecureAuth, DataViz
Support Hours: 9 AM - 5 PM EST
""";

glob return_policy = """
Returns accepted within 30 days of purchase with a receipt.
Refunds are processed to the original payment method within 5 business days.
""";

def support_agent(question: str) -> str by llm(
    incl_info={"company_context": company_info, "return_policy": return_policy}
);
sem support_agent = "Answer customer questions about our products and services.";
