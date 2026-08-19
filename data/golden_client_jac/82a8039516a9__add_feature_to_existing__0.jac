enum Sentiment {
    POSITIVE,
    NEGATIVE,
    NEUTRAL,
    MIXED
}

def analyze_sentiment(text: str) -> Sentiment by llm();
def sentiment_confidence(text: str) -> float by llm();
