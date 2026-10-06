import from app.models.core { FileMatch }
include app.services.repo_ingest;

def split_terms(text: str) -> list[str] {
    return text.split(" ");
}

def term_score(lowered_path: str, terms: list[str]) -> float {
    score: float = 0.0;
    for term in terms {
        if len(term) >= 3 and term in lowered_path {
            score += 0.18;
        }
    }
    return score;
}

def path_score(lowered_path: str) -> float {
    filename: str = last_path_part(lowered_path);
    base: str = filename;
    if "." in filename {
        base_parts: list[str] = filename.split(".");
        if len(base_parts) > 0 {
            base = base_parts[0];
        }
    }
    entry_names: list[str] = ["main", "index", "app", "server", "mod", "lib", "wsgi", "asgi", "manage", "program"];
    if base in entry_names {
        return 0.12;
    }
    if filename.startswith("readme") {
        return 0.10;
    }
    key_dirs: list[str] = [
        "orchestration", "workflow", "graph",
        "services", "service", "api", "routes", "controllers",
        "components", "views", "pages",
        "models", "schema", "agents"
    ];
    for d in key_dirs {
        if ("/" + d + "/") in ("/" + lowered_path) {
            return 0.08;
        }
    }
    return 0.0;
}

def file_score(item: FileMatch) -> float {
    return item.score;
}

def:pub search_repo(
    repo_path: str,
    prompt: str,
    meeting_text: str,
    scanned_files: list[FileMatch] | None = None
) -> list[FileMatch] {
    scanned: list[FileMatch] = scanned_files if scanned_files is not None else scan_repo(repo_path);
    ranked: list[FileMatch] = [];
    combined_text: str = prompt + " " + meeting_text;
    terms: list[str] = split_terms(combined_text.lower());
    prompt_term_count: int = len(split_terms(prompt));
    meeting_term_count: int = len(split_terms(meeting_text));
    rationale_prefix: str = "Ranked from path heuristics using " + str(prompt_term_count) + " prompt terms and " + str(meeting_term_count) + " meeting terms for: ";
    for item in scanned {
        lowered_path: str = item.path.lower();
        score: float = 0.1 + term_score(lowered_path, terms) + path_score(lowered_path);
        candidate: FileMatch = FileMatch(
            path=item.path,
            score=score,
            rationale=rationale_prefix + item.path,
            kind=item.kind
        );
        ranked.append(candidate);
    }
    ranked.sort(key=file_score, reverse=True);
    return ranked;
}
