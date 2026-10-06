import from app.services.llm_runtime { llm }
import from app.models.core { DecisionItem }
import from app.models.outputs { DocsSyncResult }
include app.services.docs_sync;

def:pub run_docs_sync(repo_path: str, content_cache: dict[str, str] | None = None) -> DocsSyncResult {
    return sync_docs(repo_path, content_cache);
}

def:pub llm_extract_doc_decisions(_doc_path: str, _doc_text: str, _draft: list[DecisionItem]) -> list[DecisionItem] by llm();
