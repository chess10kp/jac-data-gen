node Document {
    has title: str;
    has content: str;
    has summary: str = "";
}

def summarize(content: str) -> str by llm();
sem summarize = "Summarize this document in 2-3 sentences.";

walker DocumentAgent {
    has query: str;

    can process with Root entry {
        all_docs = [-->][?:Document];

        for doc in all_docs {
            if self.query.lower() in doc.content.lower() {
                doc.summary = summarize(doc.content);
                report {"title": doc.title, "summary": doc.summary};
            }
        }
    }
}
