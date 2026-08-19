with entry {
    root ++> Document(
        title="AI Overview",
        content="Artificial intelligence is transforming industries..."
    );
    root ++> Document(
        title="Weather Report",
        content="Sunny skies expected throughout the week..."
    );
    root ++> Document(
        title="Machine Learning Guide",
        content="Machine learning is a subset of AI that..."
    );

    result = root spawn DocumentAgent(query="AI");

    for doc in result.reports {
        print("## " + doc["title"]);
        print(doc["summary"]);
        print();
    }
}
