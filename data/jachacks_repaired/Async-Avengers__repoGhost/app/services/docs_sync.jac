import from os { path }
import from app.models.core { DecisionItem, FileMatch }
import from app.models.outputs { DocsSyncResult }

def read_text(file_path: str, content_cache: dict[str, str] | None = None) -> str {
    if content_cache is not None and file_path in content_cache {
        return content_cache[file_path];
    }
    text: str = "";
    try {
        with open(file_path, "r", encoding="utf-8") as handle {
            text = handle.read();
        }
    } except OSError {
        text = "";
    } except UnicodeError {
        text = "";
    }
    if content_cache is not None {
        content_cache[file_path] = text;
    }
    return text;
}

def split_lines(text: str) -> list[str] {
    return text.split("\n");
}

def trim_text(text: str) -> str {
    return text.strip();
}

def lower_text(text: str) -> str {
    return text.lower();
}

def meaningful_doc_line(lines: list[str]) -> str {
    for line in lines {
        stripped: str = trim_text(line);
        if not stripped {
            continue;
        }
        if stripped.startswith("#") {
            continue;
        }
        if stripped in ["---", "***", "___"] {
            continue;
        }
        return stripped;
    }
    return "";
}

def doc_decision_title(rel_path: str) -> str {
    lowered: str = lower_text(rel_path);
    if "readme" in lowered {
        return "README context";
    }
    if "spec" in lowered {
        return "Spec note";
    }
    return "Documentation context";
}

def:pub sync_docs(repo_path: str, content_cache: dict[str, str] | None = None) -> DocsSyncResult {
    docs: list[FileMatch] = [];
    decisions: list[DecisionItem] = [];
    if not repo_path {
        return DocsSyncResult(files=docs, decisions=decisions);
    }
    candidates = ["README.md", "readme.md", "docs/README.md", "SPEC.md", "docs/spec.md"];
    for rel_path in candidates {
        full_path = path.join(repo_path, rel_path.replace("/", path.sep));
        if path.exists(full_path) {
            content = read_text(full_path, content_cache);
            docs.append(
                FileMatch(
                    path=rel_path,
                    score=0.76,
                    rationale="Documentation file pulled into project context.",
                    kind="doc"
                )
            );
            if content {
                non_empty_lines: list[str] = [];
                content_lines: list[str] = split_lines(content);
                for line in content_lines {
                    stripped: str = trim_text(line);
                    if stripped {
                        non_empty_lines.append(stripped);
                    }
                }
                line_text: str = meaningful_doc_line(non_empty_lines);
                if line_text {
                    decisions.append(
                        DecisionItem(
                            title=doc_decision_title(rel_path),
                            detail=line_text,
                            confidence=0.61,
                            source=rel_path
                        )
                    );
                }
            }
        }
    }
    return DocsSyncResult(files=docs, decisions=decisions);
}
