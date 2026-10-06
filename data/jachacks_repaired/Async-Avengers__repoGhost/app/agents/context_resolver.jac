import from app.models.core { FileMatch }
import from app.models.workflow { WorkflowRequest }
import from app.models.outputs { ProjectContextGraph }

obj ResolvedArea {
    has phrase: str = "";
    has target: str = "";
    has rationale: str = "";
    has confidence: float = 0.0;
}

def replace_with_space(text: str, token: str) -> str {
    return text.replace(token, " ");
}

def split_on_space(text: str) -> list[str] {
    return text.split(" ");
}

def normalize_terms(text: str) -> list[str] {
    cleaned: str = text.lower();
    tokens: list[str] = [",", ".", ":", ";", "(", ")", "[", "]", "{", "}", "\n", "\r", "\t", "?", "!"];
    for token in tokens {
        cleaned = replace_with_space(cleaned, token);
    }
    terms: list[str] = [];
    parts: list[str] = split_on_space(cleaned);
    for part in parts {
        item: str = part.strip();
        if item and len(item) > 2 and item not in terms {
            terms.append(item);
        }
    }
    return terms;
}

def score_match(terms: list[str], path: str, rationale: str) -> float {
    haystack = (path + " " + rationale).lower();
    match_bonus: float = 0.0;
    for term in terms {
        if term in haystack {
            match_bonus += 0.18;
        }
    }
    high_signal_dirs: list[str] = ["orchestration", "workflow", "graph", "services", "api", "routes", "controllers", "agents"];
    mid_signal_dirs: list[str] = ["components", "views", "pages", "models", "schema"];
    lower_path: str = path.lower();
    for d in high_signal_dirs {
        if ("/" + d + "/") in ("/" + lower_path) or lower_path.startswith(d + "/") {
            match_bonus += 0.12;
            break;
        }
    }
    for d in mid_signal_dirs {
        if ("/" + d + "/") in ("/" + lower_path) or lower_path.startswith(d + "/") {
            match_bonus += 0.08;
            break;
        }
    }
    return match_bonus;
}

def resolved_area(phrase: str, target: str, rationale: str, confidence: float) -> ResolvedArea {
    return ResolvedArea(phrase=phrase, target=target, rationale=rationale, confidence=confidence);
}

def:pub resolve_context(request: WorkflowRequest, files: list[FileMatch], graph: ProjectContextGraph) -> list[ResolvedArea] {
    terms = normalize_terms(request.prompt + " " + request.meeting_text + " " + request.mode);
    resolved: list[ResolvedArea] = [];
    for item in files[:10] {
        match_score: float = score_match(terms, item.path, item.rationale);
        if match_score > 0.16 {
            resolved.append(resolved_area(
                request.prompt,
                item.path,
                "Matched request and meeting language against ranked repo paths and graph focus areas.",
                match_score
            ));
        }
    }
    if len(resolved) == 0 {
        for item in graph.focus_paths[:4] {
            resolved.append(resolved_area(
                request.prompt,
                item,
                "Fallback to graph focus path because direct lexical resolution was weak.",
                0.34
            ));
        }
    }
    return resolved;
}
