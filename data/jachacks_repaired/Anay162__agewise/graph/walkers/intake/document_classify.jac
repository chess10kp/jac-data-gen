"""DocumentClassify walker — classifies unprocessed Document nodes.

Walks all Document nodes hanging off a Patient, calls classify_document()
via by llm() to determine the document type, then updates the node's
classification field. Unprocessed documents are those with classification == 'UNKNOWN'.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.document { Document }
import from abilities.llm_abilities { classify_document }

walker DocumentClassify {

    can start with Patient entry {
        visit [-->];
    }

    can classify with Document entry {
        if here.classification != "UNKNOWN" {
            disengage;
        }

        source_meta = {
            "source": here.source,
            "filename": here.original_filename,
            "mime_type": here.mime_type
        };

        # Use LLM to classify — by llm() call
        category = classify_document(
            raw_text=here.raw_content,
            source_metadata=source_meta
        );

        here.classification = category;
        print(f"[DocumentClassify] Document {here.doc_id} classified as: {category}");
    }
}
