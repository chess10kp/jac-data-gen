import from datetime { datetime }

def get_weather() -> str { return "sunny, 21 C"; }
def get_trending_topics() -> list[str] { return ["ai", "space"]; }

obj User {
    has name: str;
    has preferences: dict;

    def get_recommendation() -> str by llm(
        incl_info={
            "current_time": datetime.now().isoformat(),
            "weather": get_weather(),
            "trending": get_trending_topics()
        }
    );

    def explain_recommendation(item: str) -> str by llm(
        incl_info={"user_name": self.name}
    );
}
