import from app.services.llm_runtime { llm }
import from app.models.outputs { RepoSummary }
import from app.models.core { FileMatch }
include app.services.repo_ingest;

def:pub run_repo_mapper(
    repo_path: str,
    scanned_files: list[FileMatch] | None = None,
    content_cache: dict[str, str] | None = None
) -> RepoSummary {
    return summarize_repo(repo_path, scanned_files, content_cache);
}

def:pub llm_repo_mapper(_repo_path: str, _scanned_files: list[FileMatch], _draft: RepoSummary) -> RepoSummary by llm();
