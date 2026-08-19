# Define the function first, then attach semantics to it.
def translate(text: str) -> str by llm();
sem translate = "Translate the given text to French. Preserve formatting and tone.";
sem translate.text = "Short, plain-language input text to translate.";

obj Product { has price: float; }
sem Product.price = "Price in USD, numeric value";

enum Priority { LOW, MEDIUM, HIGH }
sem Priority.HIGH = "Urgent: requires immediate attention";
