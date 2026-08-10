"""
Arguments: {"joy": 1, "sadness": 0.8}, ["joy", "sadness", "trust"]
Returns: {"joy": 1, "sadness": 0.8, "trust": 0, "disgust": None, ...}
"""
def emotion_mapping(emotions: dict[str, float], dataset_emotions: list[str]) -> dict[str, float | None] {
    all_emotions = [
        "joy",
        "anger",
        "sadness",
        "disgust",
        "fear",
        "trust",
        "surprise",
        "love",
        "noemo",
        "confusion",
        "anticipation"
    ];
    d = {emotion: None for emotion in all_emotions} as dict[str, float | None];
    for emotion in all_emotions {
        if emotion in dataset_emotions {
            d[emotion] = emotions.get(emotion, 0);
        }
    }
    return d;
}