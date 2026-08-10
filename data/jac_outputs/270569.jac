"""Format log messages."""
def format_logging(message: str) -> str {
    if "n_documents" in message {
        n = message.split("n_documents: ")[1];
        return "Number of documents: {}".format(n);
    } elif "vocab_size" in message {
        n = message.split("vocab_size: ")[1];
        return "Number of types: {}".format(n);
    } elif "n_words" in message {
        n = message.split("n_words: ")[1];
        return "Number of tokens: {}".format(n);
    } elif "n_topics" in message {
        n = message.split("n_topics: ")[1];
        return "Number of topics: {}".format(n);
    } elif "n_iter" in message {
        return "Initializing topic model...";
    } elif "log likelihood" in message {
        (iteration, _) = message.split("> log likelihood: ");
        return "Iteration {}".format(iteration[1:]);
    } else {
        return message;
    }
}