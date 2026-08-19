obj Customer {
    has id: str;
    has name: str;
    has tier: str;
    has email: str;
}

def draft_welcome_email(customer: Customer) -> str by llm();
