# Attach semantics to a function
sem translate = "Translate the given text to French. Preserve formatting and tone.";
def translate(text: str) -> str by llm();

# Attach semantics to a function parameter
sem translate.text = "Short, plain-language input text to translate.";

# Attach semantics to a type field
obj Product { has price: float; has currency: str; }
sem Product.price = "Price in USD, numeric value";
sem Product.currency = "Three-letter ISO 4217 currency code, e.g. USD, EUR, GBP";

# Attach semantics to an enum value
enum Priority { LOW, MEDIUM, HIGH }
sem Priority.HIGH = "Urgent: requires immediate attention";

# New feature: extract a Product from a listing using the semantics above
def extract_product(listing: str) -> Product by llm();
