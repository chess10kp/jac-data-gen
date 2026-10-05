def classify_sentiment(text: str) -> str by llm();

with entry {
    sentiment = classify_sentiment("I love how this Jac toolchain works");
    print(sentiment);
}


def function_name(arg: str) -> str by llm();
