enum Personality {
    INTROVERT,
    EXTROVERT,
    AMBIVERT
}

sem Personality.INTROVERT = "Prefers solitude and small groups, energized by alone time";
sem Personality.EXTROVERT = "Thrives in social settings, energized by interaction";
sem Personality.AMBIVERT = "Comfortable in both social and solitary settings";

obj PersonalityResult {
    has type: Personality;
    has confidence: float;
    has reasoning: str;
}

def classify_personality(bio: str) -> Personality by llm();
def classify_personality_detailed(bio: str) -> PersonalityResult by llm();
