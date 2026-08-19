glob company_info = "Company: TechCorp | Products: CloudDB, SecureAuth, DataViz | Support Hours: 9 AM - 5 PM EST | Support Email: support@techcorp.com";

def support_agent(question: str) -> str by llm(
    incl_info={"company_context": company_info}
);

sem support_agent = "Answer customer questions using only the provided company context. If the answer isn't in the context, say you don't know.";

with entry {
    questions = ["What products do you offer?", "What are your support hours?"];
    for q in questions {
        try {
            print(support_agent(q));
        } except Exception as e {
            print(f"Support agent unavailable: {e}");
        }
    }
}
