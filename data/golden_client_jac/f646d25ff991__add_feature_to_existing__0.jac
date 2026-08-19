import from byllm.lib { Model }

glob llm = Model(model_name="gpt-4o");

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
                word_count = len(doc.content.split());
                report {"title": doc.title, "summary": doc.summary, "words": word_count};
            }
        }
    }
}
