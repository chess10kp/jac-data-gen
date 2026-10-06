import from app.services.llm_runtime { llm }
import from app.models.core { FileMatch }
include app.services.search_index;

def:pub run_code_search(
    repo_path: str,
    prompt: str,
    meeting_text: str,
    scanned_files: list[FileMatch] | None = None
) -> list[FileMatch] {
    matches: list[FileMatch] = search_repo(repo_path, prompt, meeting_text, scanned_files);
    return matches;
}

def:pub llm_rerank_code_search(_prompt: str, _meeting_text: str, _candidates: list[FileMatch]) -> list[FileMatch] by llm();
