node Document {
    has title: str;
    has content: str;
    has summary: str = "";
}

def summarize(content: str) -> str by llm();
sem summarize = "Summarize this document in 2-3 sentences.";

"""Search documents for matching content."""
def search_documents(query: str, docs: list[Document]) -> list[str] {
    results = [];
    for doc in docs {
        if query.lower() in doc.content.lower() {
            results.append(doc.title);
        }
    }
    return results;
}

walker DocumentAgent {
    has query: str;

    can process with Root entry {
        all_docs = [root -->][?:Document];
        relevant = search_documents(self.query, all_docs);

        for doc in all_docs {
            if doc.title in relevant and doc.summary == "" {
                doc.summary = summarize(doc.content);
            }
            if doc.title in relevant {
                report {"title": doc.title, "summary": doc.summary};
            }
        }
    }
}
