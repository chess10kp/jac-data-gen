# integrations/impl/github.impl.jac

import hmac;
import from hashlib { sha256 }
import from github { Github }
import from re { findall }
import from os { environ }

impl validate_webhook_signature(payload: bytes, signature: str, secret: str) -> bool {
    expected = "sha256=" + hmac.new(secret.encode(), payload, sha256).hexdigest();
    try {
        return hmac.compare_digest(expected, signature);
    } except Exception { # jac:ignore[W2052]
        return False;
    }
}

impl fetch_pr_diff(pr_url: str) -> PRDiff {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    parts = pr_url.rstrip("/").split("/");
    pr_number = int(parts[-1]);
    repo_name = parts[-4] + "/" + parts[-3];
    repo = g.get_repo(repo_name);
    pr = repo.get_pull(pr_number);
    changed_files = [];
    diff_parts = [];
    for f in pr.get_files() {
        fn = str(getattr(f, "filename", ""));
        changed_files.append(fn);
        patch = getattr(f, "patch", None);
        if patch {
            diff_parts.append(f"--- {fn}\n{patch}");
        }
    }
    unified_diff = "\n".join(diff_parts);
    changed_apis = findall(r"^\+.*(?:def|class|walker|node)\s+(\w+)", unified_diff, flags=8);
    api_list: list[str] = [];
    for x in set(changed_apis) {
        api_list.append(str(x));
    }
    return PRDiff(
        pr_number=pr_number,
        pr_url=pr_url,
        changed_files=changed_files,
        unified_diff=unified_diff,
        changed_apis=api_list
    );
}

impl fetch_file_content(repo_name: str, file_path: str, ref: str) -> str {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    try {
        file_obj = repo.get_contents(file_path, ref=ref);
        if isinstance(file_obj, list) {
            picked = None;
            for item in file_obj {
                picked = item;
                break;
            }
            if picked is None {
                return "";
            }
            file_obj = picked;
        }
        raw = getattr(file_obj, "decoded_content", b"");
        if isinstance(raw, str) {
            return raw;
        }
        dec = getattr(raw, "decode", None);
        if dec {
            return str(dec("utf-8"));
        }
        return str(raw);
    } except Exception as e { # jac:ignore[W2052]
        print(f"fetch_file_content failed for {file_path}: {e}");
        return "";
    }
}

impl post_pr_comment(pr_url: str, body: str) -> None {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    parts = pr_url.rstrip("/").split("/");
    pr_number = int(parts[-1]);
    repo_name = parts[-4] + "/" + parts[-3];
    repo = g.get_repo(repo_name);
    pr = repo.get_pull(pr_number);
    pr.create_issue_comment(body);
}

impl get_repo_tree(repo_name: str, branch: str) -> list[dict] {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    tree = repo.get_git_tree(repo.get_branch(branch).commit.sha, recursive=True);
    out: list[dict] = [];
    for item in tree.tree {
        if item.type == "blob" {
            out.append({"path": item.path, "type": item.type, "size": item.size});
        }
    }
    return out;
}

impl list_commit_files(repo_name: str, commit_sha: str) -> list[str] {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    try {
        c = repo.get_commit(commit_sha);
        out: list[str] = [];
        for f in c.files {
            out.append(str(getattr(f, "filename", "")));
        }
        return out;
    } except Exception as e { # jac:ignore[W2052]
        print(f"list_commit_files: {e}");
        return [];
    }
}

impl get_parent_commit_sha(repo_name: str, commit_sha: str) -> str {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    try {
        c = repo.get_commit(commit_sha);
        if c.parents {
            return str(c.parents[0].sha);
        }
    } except Exception as e { # jac:ignore[W2052]
        print(f"get_parent_commit_sha: {e}");
    }
    return "";
}

impl create_branch_from_sha(repo_name: str, new_branch: str, sha: str) -> None {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    ref = f"refs/heads/{new_branch}";
    try {
        repo.create_git_ref(ref, sha);
    } except Exception as e { # jac:ignore[W2052]
        print(f"create_branch_from_sha: {e}");
    }
}

impl update_file_on_branch(
    repo_name: str,
    file_path: str,
    branch: str,
    new_content: str,
    commit_message: str
) -> None {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    try {
        existing = repo.get_contents(file_path, ref=branch);
        if isinstance(existing, list) {
            picked = None;
            for item in existing {
                picked = item;
                break;
            }
            if picked is None {
                return;
            }
            existing = picked;
        }
        sha = str(getattr(existing, "sha", ""));
        repo.update_file(file_path, commit_message, new_content, sha, branch=branch);
    } except Exception as e { # jac:ignore[W2052]
        print(f"update_file_on_branch: {e}");
        try {
            repo.create_file(file_path, commit_message, new_content, branch=branch);
        } except Exception as e2 { # jac:ignore[W2052]
            print(f"create_file fallback: {e2}");
        }
    }
}

impl open_pull_request(
    repo_name: str,
    title: str,
    body: str,
    head_branch: str,
    base_branch: str
) -> str {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    try {
        pr = repo.create_pull(title=title, body=body, head=head_branch, base=base_branch);
        return str(getattr(pr, "html_url", ""));
    } except Exception as e { # jac:ignore[W2052]
        print(f"open_pull_request: {e}");
        return "";
    }
}

impl find_open_pr_for_branch(repo_name: str, head_branch: str) -> str {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    try {
        parts = repo_name.split("/");
        head = f"{parts[0]}:{head_branch}";
        pulls = repo.get_pulls(state="open", head=head);
        for p in pulls {
            return str(getattr(p, "html_url", ""));
        }
    } except Exception as e { # jac:ignore[W2052]
        print(f"find_open_pr_for_branch: {e}");
    }
    return "";
}

impl get_default_branch(repo_name: str) -> str {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    try {
        return str(repo.default_branch);
    } except Exception { # jac:ignore[W2052]
        return "main";
    }
}

impl get_branch_head_sha(repo_name: str, branch: str) -> str {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    repo = g.get_repo(repo_name);
    try {
        b = repo.get_branch(branch);
        return str(b.commit.sha);
    } except Exception { # jac:ignore[W2052]
        return "";
    }
}

impl list_open_issues(repo_name: str, limit: int) -> list[dict] {
    g = Github(environ.get("GITHUB_TOKEN", ""));
    try {
        repo = g.get_repo(repo_name);
        out: list[dict] = [];
        n = 0;
        lim = int(limit) if limit else 100;
        for issue in repo.get_issues(state="open", sort="updated", direction="desc") {
            pr = getattr(issue, "pull_request", None);
            if pr is not None {
                continue;
            }
            labels: list[str] = [];
            for lb in issue.labels {
                labels.append(str(getattr(lb, "name", "")));
            }
            upd = "";
            uat = getattr(issue, "updated_at", None);
            if uat {
                iso = getattr(uat, "isoformat", None);
                if iso {
                    upd = str(iso());
                } else {
                    upd = str(uat);
                }
            }
            out.append(
                {
                    "number": int(getattr(issue, "number", 0)),
                    "title": str(getattr(issue, "title", "") or ""),
                    "html_url": str(getattr(issue, "html_url", "") or ""),
                    "state": str(getattr(issue, "state", "open") or "open"),
                    "labels": labels,
                    "updated_at": upd
                }
            );
            n += 1;
            if n >= lim {
                break;
            }
        }
        return out;
    } except Exception as e { # jac:ignore[W2052]
        print(f"list_open_issues: {e}");
        return [];
    }
}
