obj Customer {
    has id: str;
    has name: str;
    has tier: str;
    has email: str;
}

# Object-level semantic
sem Customer = "A customer record in the CRM system";

# Attribute-level semantics
sem Customer.id = "Unique customer identifier (UUID format)";
sem Customer.name = "Full legal name of the customer";
sem Customer.tier = "Service tier: 'basic', 'premium', or 'enterprise'";
sem Customer.email = "Primary contact email address for the customer";

# Enum value semantics
enum Priority { LOW, MEDIUM, HIGH }
sem Priority.HIGH = "Urgent: requires immediate attention";

def draft_welcome_email(customer: Customer) -> str by llm();
