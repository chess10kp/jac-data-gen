def get_weather(city: str) -> str { return fetch_weather_api(city); }
def search_web(query: str) -> list[str] { return web_search_api(query); }

# The LLM decides which tools to call and in what order
def answer_question(question: str) -> str
    by llm(tools=[get_weather, search_web]);
