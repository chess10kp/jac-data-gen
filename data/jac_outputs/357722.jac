"""Format the recommendation string by removing the recommendation grade."""
def formatRecommendation(recommendation_text: str) -> str {
    parts = recommendation_text.split('.');
    parts.pop();
    return '.'.join(parts) + '.';
}