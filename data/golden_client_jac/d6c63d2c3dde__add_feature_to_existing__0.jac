obj PersonalityResult {
    has type: Personality;
    has confidence: float;
    has reasoning: str;
}

def classify_personality_detailed(bio: str) -> PersonalityResult by llm();
