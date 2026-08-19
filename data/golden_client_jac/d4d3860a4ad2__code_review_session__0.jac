enum Sentiment { POSITIVE, NEGATIVE, NEUTRAL }

# The enum constrains the LLM to one of three valid labels
def classify_sentiment(text: str) -> Sentiment by llm;

enum Priority { LOW, MEDIUM, HIGH, CRITICAL }
def triage_ticket(description: str) -> Priority by llm();

obj Ingredient {
    has name: str, cost: float, carby: bool;
}
sem Ingredient.cost = "Estimated cost in USD";
sem Ingredient.carby = "True if high in carbohydrates";

def plan_shopping(recipe: str) -> list[Ingredient] by llm();
