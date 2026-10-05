"""GitHub API helpers for fetching package manifests."""

import from tools.env_util { ensure_dotenv_loaded }

sem parse_github_repo_url = "Parse owner and repo from a github.com URL.";
sem fetch_github_lockfile = "Fetch a repo manifest file (raw GitHub, no 1MB cap).";
sem fetch_github_npm_manifest = "Fetch package-lock.json or fallback to package.json.";

def parse_github_repo_url(repo_url: str) -> dict {
    url = repo_url.strip().rstrip("/");
    if url.endswith(".git") {
        url = url[0:-4];
    }
    marker = "github.com/";
    if marker not in url {
        return {"ok": False, "error": "Not a github.com URL"};
    }
    path = url.split(marker, 1)[1];
    parts = [p for p in path.split("/") if p];
    if len(parts) < 2 {
        return {"ok": False, "error": "Expected https://github.com/owner/repo"};
    }
    return {"ok": True, "owner": parts[0], "repo": parts[1]};
}

def _github_headers(token: str) -> dict {
    headers = {"Accept": "application/vnd.github+json"};
    if token {
        headers["Authorization"] = f"Bearer {token}";
    }
    return headers;
}

def _fetch_via_raw(
    owner: str,
    repo: str,
    branch: str,
    filename: str,
    headers: dict
) -> dict {
    import requests;

    raw_url = (
        f"https://raw.githubusercontent.com/{owner}/{repo}/"
        f"{branch}/{filename}"
    );
    resp = requests.get(raw_url, headers=headers, timeout=120);
    if resp.status_code == 404 {
        return {
            "ok": False,
            "error": f"{filename} not found on branch {branch}",
            "owner": owner,
            "repo": repo
        };
    }
    if resp.status_code != 200 {
        return {
            "ok": False,
            "error": f"raw fetch {resp.status_code}: {resp.text[:200]}",
            "owner": owner,
            "repo": repo
        };
    }
    if not resp.text {
        return {
            "ok": False,
            "error": f"{filename} empty on branch {branch}",
            "owner": owner,
            "repo": repo
        };
    }
    return {
        "ok": True,
        "owner": owner,
        "repo": repo,
        "filename": filename,
        "text": resp.text,
        "branch": branch,
        "source": "raw"
    };
}

def _fetch_via_contents_api(
    owner: str,
    repo: str,
    filename: str,
    headers: dict
) -> dict {
    import base64;
    import requests;

    api_url = (
        f"https://api.github.com/repos/{owner}/{repo}/contents/{filename}"
    );
    resp = requests.get(api_url, headers=headers, timeout=45);
    if resp.status_code == 404 {
        return {
            "ok": False,
            "error": f"{filename} not found on default branch",
            "owner": owner,
            "repo": repo
        };
    }
    if resp.status_code != 200 {
        return {
            "ok": False,
            "error": f"GitHub API {resp.status_code}: {resp.text[:200]}",
            "owner": owner,
            "repo": repo
        };
    }
    payload = resp.json();
    if isinstance(payload, list) {
        return {
            "ok": False,
            "error": f"{filename} is a directory, not a file",
            "owner": owner,
            "repo": repo
        };
    }
    content_b64 = str(payload.get("content", "")).strip();
    text = "";
    if content_b64 {
        text = base64.b64decode(content_b64).decode("utf-8", errors="replace");
    }
    if not text {
        download_url = str(payload.get("download_url", "")).strip();
        if download_url {
            raw_resp = requests.get(download_url, headers=headers, timeout=120);
            if raw_resp.status_code == 200 and raw_resp.text {
                text = raw_resp.text;
            }
        }
    }
    if not text {
        file_size = payload.get("size", 0);
        return {
            "ok": False,
            "error": (
                f"{filename} empty via Contents API (size={file_size})"
            ),
            "owner": owner,
            "repo": repo
        };
    }
    return {
        "ok": True,
        "owner": owner,
        "repo": repo,
        "filename": filename,
        "text": text,
        "source": "contents_api"
    };
}

def fetch_github_lockfile(
    repo_url: str,
    filename: str = "package-lock.json"
) -> dict {
    ensure_dotenv_loaded();
    import os;
    import requests;

    parsed = parse_github_repo_url(repo_url);
    if not parsed["ok"] {
        return parsed;
    }
    owner = str(parsed["owner"]);
    repo = str(parsed["repo"]);
    token = os.environ.get("GITHUB_TOKEN", "");
    headers = _github_headers(token);

    branch = "main";
    repo_api = f"https://api.github.com/repos/{owner}/{repo}";
    repo_resp = requests.get(repo_api, headers=headers, timeout=45);
    if repo_resp.status_code == 200 {
        repo_body = repo_resp.json();
        if isinstance(repo_body, dict) and "default_branch" in repo_body {
            branch = str(repo_body["default_branch"]);
        }
    }

    raw_result = _fetch_via_raw(owner, repo, branch, filename, headers);
    if raw_result["ok"] {
        return raw_result;
    }

    return _fetch_via_contents_api(owner, repo, filename, headers);
}

def fetch_github_npm_manifest(repo_url: str) -> dict {
    lock = fetch_github_lockfile(repo_url, "package-lock.json");
    lock_text = "";
    if "text" in lock {
        lock_text = str(lock["text"]);
    }
    if lock["ok"] and lock_text {
        lock["manifest_kind"] = "lockfile";
        return lock;
    }
    lock_err = str(lock.get("error", ""));
    pkg = fetch_github_lockfile(repo_url, "package.json");
    pkg_text = "";
    if "text" in pkg {
        pkg_text = str(pkg["text"]);
    }
    if pkg["ok"] and pkg_text {
        pkg["manifest_kind"] = "package_json";
        pkg["lockfile_warning"] = lock_err;
        return pkg;
    }
    return {
        "ok": False,
        "error": (
            "Neither package-lock.json nor package.json could be loaded. "
            f"Lockfile: {lock_err}"
        ),
        "owner": lock.get("owner", pkg.get("owner", "")),
        "repo": lock.get("repo", pkg.get("repo", ""))
    };
}

def _github_code_search(
    owner: str,
    repo: str,
    query: str,
    headers: dict
) -> list[str] {
    import requests;

    url = "https://api.github.com/search/code";
    params = {"q": query, "per_page": 10};
    try {
        resp = requests.get(url, headers=headers, params=params, timeout=15);
        if resp.status_code != 200 {
            return [];
        }
        items = resp.json().get("items", []);
        if not isinstance(items, list) {
            return [];
        }
        paths: list[str] = [];
        for item in items {
            if isinstance(item, dict) and item.get("path") {
                paths.append(str(item["path"]));
            }
        }
        return paths;
    } except Exception {
        return [];
    }
}

def search_github_package_imports(
    repo_url: str,
    package_name: str,
    ecosystem: str = "npm"
) -> list[str] {
    ensure_dotenv_loaded();
    import os;

    parsed = parse_github_repo_url(repo_url);
    if not parsed["ok"] {
        return [];
    }
    owner = str(parsed["owner"]);
    repo = str(parsed["repo"]);
    pkg = str(package_name).strip();
    if not pkg {
        return [];
    }
    if pkg.lower() == repo.lower() {
        return [];
    }

    token = os.environ.get("GITHUB_TOKEN", "");
    if not token {
        return [];
    }

    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": f"Bearer {token}",
    };

    eco = str(ecosystem).lower();
    if eco == "auto" {
        eco = "npm";
    }
    scope = f"repo:{owner}/{repo}";
    queries: list[str] = [];

    if eco == "pypi" {
        queries.append(f"import {pkg} {scope}");
        queries.append(f"from {pkg} {scope}");
    } elif eco == "go" {
        queries.append(f'"{pkg}" {scope} extension:go');
    } elif eco == "maven" {
        artifact = pkg;
        if ":" in pkg {
            artifact = pkg.split(":", 1)[1];
        }
        queries.append(f"import {artifact} {scope}");
    } else {
        queries.append(f"import {pkg} {scope}");
        queries.append(f"from {pkg} {scope}");
        queries.append(f'from "{pkg}" {scope}');
        queries.append(f"from '{pkg}' {scope}");
        queries.append(f"require({pkg}) {scope}");
        queries.append(f'require("{pkg}") {scope}');
        queries.append(f"require('{pkg}') {scope}");
        if pkg.startswith("@") {
            queries.append(f'"{pkg}" {scope}');
        }
        if "-" in pkg {
            queries.append(f'"{pkg}" {scope}');
        }
    }

    seen: dict = {};
    merged: list[str] = [];
    for query in queries {
        for path in _github_code_search(owner, repo, query, headers) {
            if path in seen {
                continue;
            }
            seen[path] = True;
            merged.append(path);
            if len(merged) >= 10 {
                return merged;
            }
        }
    }
    if not merged {
        fallback_queries: list[str] = [
            f"{pkg} language:TypeScript {scope}",
            f"{pkg} language:JavaScript {scope}",
        ];
        for query in fallback_queries {
            for path in _github_code_search(owner, repo, query, headers) {
                if path in seen {
                    continue;
                }
                seen[path] = True;
                merged.append(path);
                if len(merged) >= 10 {
                    return merged;
                }
            }
        }
    }
    return merged;
}
