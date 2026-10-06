"""PlainEnglishTranslator walker — generates plain-English summaries of documents.

Walks Document nodes and uses by llm() to create human-readable summaries
targeted at elderly patients or their adult children.
"""

import from graph.nodes.patient { Patient }
import from graph.nodes.document { Document }
import from abilities.llm_abilities { translate_to_plain_english }

walker PlainEnglishTranslator {

    can start with Patient entry {
        visit [-->];
    }

    can translate with Document entry {
        if here.plain_english_summary != "" or here.raw_content == "" {
            disengage;
        }

        summary = translate_to_plain_english(
            technical_content=here.raw_content[:4000],  # truncate for LLM
            content_type=here.classification,
            reading_level=6
        );

        here.plain_english_summary = summary;
        print(f"[PlainEnglishTranslator] Translated doc {here.doc_id} ({here.classification})");
    }
}
