def add(a: float, b: float) -> float { return a + b; }
def multiply(a: float, b: float) -> float { return a * b; }
def search_db(query: str) -> str { return query; }
def get_time() -> str { return "12:00"; }

# With temperature control
def generate_story(prompt: str) -> str by llm(temperature=0.9);
def extract_facts(text: str) -> str by llm(temperature=0.0);

# With max tokens
def summarize(text: str) -> str by llm(max_tokens=100);

# With tools (enables ReAct loop)
def calculate(expression: str) -> float by llm(tools=[add, multiply]);

# With additional context
def personalized_greeting(name: str) -> str by llm(
    incl_info={"current_time": get_time(), "location": "NYC"}
);

# With streaming
def generate_essay(topic: str) -> str by llm(stream=True);

# With streaming + logging
def smart_answer(question: str) -> str by llm(
    tools=[search_db], stream=True, logging=True
);

# Multi-turn - bind a caller-owned list as conversation history
glob history: list = [];
def chat(message: str) -> str by llm(
    tools=[search_db],
    conversation=history
);

# New feature: a translation helper
def translate(text: str, target_language: str) -> str by llm(temperature=0.3);
sem translate = "Translate the given text into the target language.";
