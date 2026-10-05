# walkers/ingest.jac

import from nodes.data_nodes { DocumentNode }

walker ingest_documents {

    has files: list = [];

    can ingest with Root entry {

        # Truncate content to ~6,000 chars per file (~1,500 tokens) so four
        # sequential agent calls stay well within the 30k token/min org limit.
        MAX_CHARS = 6000;

        for f in self.files {
            doc = DocumentNode();
            doc.filename = f["filename"];
            raw_content = f["content"];
            doc.content = raw_content[:MAX_CHARS] if len(raw_content) > MAX_CHARS else raw_content;
            doc.doc_type = f["doc_type"];

            here ++> doc;

            print("📄 Loaded: " + f["filename"]);
        }

        print("✅ All documents ingested!");
    }
}