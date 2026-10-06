import from os { path, walk }
import from re { `match }
import from subprocess { run, PIPE, DEVNULL }
import from tempfile { mkdtemp }
import from shutil { rmtree }
import from app.models.outputs { RepoSummary }
import from app.models.core { FileMatch }

glob IGNORE_DIRS: list[str] = [
    ".git", ".jac", ".jaseci", "node_modules", "dist", "build", ".vite", "venv", ".venv",
    "__pycache__", ".next", ".nuxt", "target", "vendor", ".cargo", "out", ".output",
    ".turbo", ".svelte-kit", "coverage", ".nyc_output", "bin", "obj", ".idea", ".vscode"
];

def should_skip_dir(name: str) -> bool {
    return name in IGNORE_DIRS or (name.startswith(".") and name not in [".github"]);
}

def is_github_url(repo_path: str) -> bool {
    if not repo_path {
        return False;
    }
    return `match(r"^https?://github\.com/[^/\s]+/[^/\s]+(\.git)?(/.*)?$", repo_path.strip()) is not None;
}

def clone_github_repo(url: str) -> str {
    tmp_dir: str = mkdtemp(prefix="repoghost_gh_");
    clean_url: str = url.strip();
    if not clean_url.endswith(".git") {
        clean_url = clean_url + ".git";
    }
    try {
        proc = run(
            ["git", "clone", "--depth=1", "--single-branch", clean_url, tmp_dir],
            stdout=DEVNULL,
            stderr=PIPE,
            timeout=60
        );
        if proc.returncode != 0 {
            rmtree(tmp_dir, ignore_errors=True);
            return "";
        }
    } except OSError {
        rmtree(tmp_dir, ignore_errors=True);
        return "";
    } except Exception {
        rmtree(tmp_dir, ignore_errors=True);
        return "";
    }
    return tmp_dir;
}

def should_include_file(name: str) -> bool {
    lower: str = name.lower();
    exts: list[str] = [
        # Jac
        ".jac",
        # Python
        ".py", ".pyi",
        # JavaScript / TypeScript / Web
        ".js", ".mjs", ".cjs", ".jsx", ".ts", ".tsx",
        ".html", ".htm", ".css", ".scss", ".sass", ".less",
        ".vue", ".svelte",
        # Go
        ".go",
        # Rust
        ".rs",
        # Java / Kotlin
        ".java", ".kt", ".kts",
        # C / C++
        ".c", ".h", ".cpp", ".cc", ".cxx", ".hpp",
        # C#
        ".cs",
        # Ruby
        ".rb",
        # PHP
        ".php",
        # Swift
        ".swift",
        # Dart
        ".dart",
        # Shell
        ".sh", ".bash", ".zsh",
        # Config / manifest
        ".json", ".toml", ".yaml", ".yml", ".xml", ".gradle", ".properties",
        # Docs
        ".md", ".mdx", ".txt", ".rst"
    ];
    for ext in exts {
        if lower.endswith(ext) {
            return True;
        }
    }
    if lower in ["dockerfile", "makefile", "rakefile", "gemfile", "procfile", "brewfile"] {
        return True;
    }
    return False;
}

def is_entry_point(name: str) -> bool {
    lower: str = name.lower();
    entries: list[str] = [
        "main.jac", "main.py", "main.go", "main.rs", "main.ts", "main.js", "main.dart",
        "index.js", "index.ts", "index.jsx", "index.tsx",
        "app.py", "app.js", "app.ts", "app.jsx", "app.tsx",
        "server.py", "server.js", "server.ts",
        "manage.py", "wsgi.py", "asgi.py",
        "program.cs", "lib.rs"
    ];
    return lower in entries;
}

def is_config_file(name: str) -> bool {
    lower: str = name.lower();
    configs: list[str] = [
        "package.json", "jac.toml", "cargo.toml", "go.mod", "pyproject.toml",
        "setup.py", "setup.cfg", "requirements.txt", "pipfile",
        "pom.xml", "build.gradle", "build.gradle.kts",
        "pubspec.yaml", "gemfile", "composer.json",
        "tsconfig.json", "jsconfig.json",
        "vite.config.js", "vite.config.ts",
        "next.config.js", "next.config.ts",
        "nuxt.config.js", "nuxt.config.ts",
        "webpack.config.js", "rollup.config.js",
        "dockerfile", "docker-compose.yml", "docker-compose.yaml"
    ];
    return lower in configs;
}

def scored_match(rel_path: str, file_name: str) -> FileMatch {
    if is_entry_point(file_name) {
        return FileMatch(path=rel_path, score=0.95, rationale="Application entry point.", kind="file");
    }
    if is_config_file(file_name) {
        return FileMatch(path=rel_path, score=0.92, rationale="Project config or manifest — reveals stack and dependencies.", kind="file");
    }
    if file_name.endswith(".sv.jac") {
        return FileMatch(path=rel_path, score=0.82, rationale="Jac server workflow or service module.", kind="file");
    }
    if file_name.endswith(".cl.jac") {
        return FileMatch(path=rel_path, score=0.74, rationale="Jac client UI or hook module.", kind="file");
    }
    lower: str = file_name.lower();
    if lower.startswith("readme") {
        return FileMatch(path=rel_path, score=0.68, rationale="Project documentation entry point.", kind="doc");
    }
    if "/components/" in rel_path or "/pages/" in rel_path or "/views/" in rel_path {
        return FileMatch(path=rel_path, score=0.72, rationale="UI component or page.", kind="file");
    }
    if "/api/" in rel_path or "/routes/" in rel_path or "/controllers/" in rel_path {
        return FileMatch(path=rel_path, score=0.78, rationale="API route or controller.", kind="file");
    }
    if "/services/" in rel_path or "/agents/" in rel_path {
        return FileMatch(path=rel_path, score=0.75, rationale="Service or agent module.", kind="file");
    }
    if "/models/" in rel_path or "/schema/" in rel_path or "/types/" in rel_path {
        return FileMatch(path=rel_path, score=0.70, rationale="Data model or type definition.", kind="file");
    }
    if "/tests/" in rel_path or "/__tests__/" in rel_path or ".test." in rel_path or ".spec." in rel_path {
        return FileMatch(path=rel_path, score=0.50, rationale="Test file.", kind="file");
    }
    return FileMatch(path=rel_path, score=0.35, rationale="Included from recursive repo scan.", kind="file");
}

def read_file_head(full_path: str, content_cache: dict[str, str] | None = None) -> str {
    if content_cache is not None and full_path in content_cache {
        return content_cache[full_path];
    }
    text: str = "";
    try {
        with open(full_path, "r", encoding="utf-8", errors="ignore") as f {
            text = f.read();
        }
    } except OSError {
        text = "";
    } except UnicodeError {
        text = "";
    }
    if content_cache is not None {
        content_cache[full_path] = text;
    }
    return text;
}

def last_path_part(text: str) -> str {
    parts: list[str] = text.split("/");
    if len(parts) > 0 {
        return parts[len(parts) - 1];
    }
    return text;
}

def detect_project_type(repo_path: str, files: list[FileMatch], content_cache: dict[str, str] | None = None) -> str {
    for item in files {
        file_name: str = last_path_part(item.path);
        name: str = file_name.lower();
        full_path: str = path.join(repo_path, item.path);

        if name == "package.json" {
            text: str = read_file_head(full_path, content_cache);
            if "\"next\"" in text { return "▲ Next.js App"; }
            if "\"nuxt\"" in text { return "💚 Nuxt.js App"; }
            if "\"react\"" in text { return "⚛️ React App"; }
            if "\"vue\"" in text { return "💚 Vue App"; }
            if "\"@sveltejs/kit\"" in text or "\"svelte\"" in text { return "🔥 Svelte App"; }
            if "\"express\"" in text or "\"fastify\"" in text or "\"koa\"" in text { return "🟢 Node.js Service"; }
            if "\"electron\"" in text { return "⚡ Electron App"; }
            return "🟢 Node.js Project";
        }
        if name == "cargo.toml" { return "🦀 Rust Project"; }
        if name == "go.mod" { return "🐹 Go Project"; }
        if name == "pubspec.yaml" { return "💙 Flutter App"; }
        if name == "pom.xml" { return "☕ Java (Maven) Project"; }
        if name in ["build.gradle", "build.gradle.kts"] { return "☕ Java/Kotlin (Gradle) Project"; }
        if name == "jac.toml" { return "👻 Jac Project"; }

        if name == "pyproject.toml" {
            text: str = read_file_head(full_path, content_cache);
            if "fastapi" in text { return "🐍 Python FastAPI Service"; }
            if "django" in text { return "🐍 Python Django App"; }
            if "flask" in text { return "🐍 Python Flask Service"; }
            return "🐍 Python Project";
        }
        if name == "requirements.txt" {
            text: str = read_file_head(full_path, content_cache);
            if "fastapi" in text { return "🐍 Python FastAPI Service"; }
            if "django" in text { return "🐍 Python Django App"; }
            if "flask" in text { return "🐍 Python Flask Service"; }
            return "🐍 Python Project";
        }
        if name == "gemfile" {
            text: str = read_file_head(full_path, content_cache);
            if "rails" in text { return "🛤️ Ruby on Rails App"; }
            return "💎 Ruby Project";
        }
        if name == "composer.json" { return "🐘 PHP Project"; }
    }

    ext_py: int = 0;
    ext_go: int = 0;
    ext_rs: int = 0;
    ext_java: int = 0;
    ext_kt: int = 0;
    ext_ts: int = 0;
    ext_js: int = 0;
    ext_cs: int = 0;
    ext_rb: int = 0;
    ext_php: int = 0;
    ext_swift: int = 0;
    ext_dart: int = 0;
    ext_jac: int = 0;
    for item in files {
        lower: str = item.path.lower();
        if lower.endswith(".py") { ext_py = ext_py + 1; }
        elif lower.endswith(".go") { ext_go = ext_go + 1; }
        elif lower.endswith(".rs") { ext_rs = ext_rs + 1; }
        elif lower.endswith(".java") { ext_java = ext_java + 1; }
        elif lower.endswith(".kt") { ext_kt = ext_kt + 1; }
        elif lower.endswith(".ts") or lower.endswith(".tsx") { ext_ts = ext_ts + 1; }
        elif lower.endswith(".js") or lower.endswith(".jsx") { ext_js = ext_js + 1; }
        elif lower.endswith(".cs") { ext_cs = ext_cs + 1; }
        elif lower.endswith(".rb") { ext_rb = ext_rb + 1; }
        elif lower.endswith(".php") { ext_php = ext_php + 1; }
        elif lower.endswith(".swift") { ext_swift = ext_swift + 1; }
        elif lower.endswith(".dart") { ext_dart = ext_dart + 1; }
        elif lower.endswith(".jac") { ext_jac = ext_jac + 1; }
    }

    best: int = 0;
    best_lang: str = "💻 Software Project";
    if ext_py > best { best = ext_py; best_lang = "🐍 Python Project"; }
    if ext_go > best { best = ext_go; best_lang = "🐹 Go Project"; }
    if ext_rs > best { best = ext_rs; best_lang = "🦀 Rust Project"; }
    if ext_java > best { best = ext_java; best_lang = "☕ Java Project"; }
    if ext_kt > best { best = ext_kt; best_lang = "🎯 Kotlin Project"; }
    if ext_ts > best { best = ext_ts; best_lang = "🔷 TypeScript Project"; }
    if ext_js > best { best = ext_js; best_lang = "🟡 JavaScript Project"; }
    if ext_cs > best { best = ext_cs; best_lang = "🔷 C# Project"; }
    if ext_rb > best { best = ext_rb; best_lang = "💎 Ruby Project"; }
    if ext_php > best { best = ext_php; best_lang = "🐘 PHP Project"; }
    if ext_swift > best { best = ext_swift; best_lang = "🍎 Swift Project"; }
    if ext_dart > best { best = ext_dart; best_lang = "🎯 Dart Project"; }
    if ext_jac > best { best_lang = "👻 Jac Project"; }

    return best_lang;
}

def detect_frameworks(repo_path: str, files: list[FileMatch], content_cache: dict[str, str] | None = None) -> list[str] {
    frameworks: list[str] = [];
    for item in files {
        lower: str = item.path.lower();
        name: str = last_path_part(lower);
        full_path: str = path.join(repo_path, item.path);

        if name == "package.json" {
            text: str = read_file_head(full_path, content_cache);
            if "\"react\"" in text and "React" not in frameworks { frameworks.append("React"); }
            if "\"next\"" in text and "Next.js" not in frameworks { frameworks.append("Next.js"); }
            if "\"vue\"" in text and "Vue" not in frameworks { frameworks.append("Vue"); }
            if "\"nuxt\"" in text and "Nuxt.js" not in frameworks { frameworks.append("Nuxt.js"); }
            if "\"svelte\"" in text and "Svelte" not in frameworks { frameworks.append("Svelte"); }
            if "\"express\"" in text and "Express" not in frameworks { frameworks.append("Express"); }
            if "\"fastify\"" in text and "Fastify" not in frameworks { frameworks.append("Fastify"); }
            if "\"tailwindcss\"" in text and "Tailwind" not in frameworks { frameworks.append("Tailwind"); }
            if "\"vite\"" in text and "Vite" not in frameworks { frameworks.append("Vite"); }
            if "\"electron\"" in text and "Electron" not in frameworks { frameworks.append("Electron"); }
            if "\"typescript\"" in text and "TypeScript" not in frameworks { frameworks.append("TypeScript"); }
            if "\"prisma\"" in text and "Prisma" not in frameworks { frameworks.append("Prisma"); }
        }
        if name == "jac.toml" and "Jac" not in frameworks { frameworks.append("Jac"); }
        if name == "cargo.toml" and "Rust" not in frameworks { frameworks.append("Rust"); }
        if name == "go.mod" and "Go" not in frameworks { frameworks.append("Go"); }

        if name in ["requirements.txt", "pyproject.toml"] {
            text: str = read_file_head(full_path, content_cache);
            if "fastapi" in text and "FastAPI" not in frameworks { frameworks.append("FastAPI"); }
            if "django" in text and "Django" not in frameworks { frameworks.append("Django"); }
            if "flask" in text and "Flask" not in frameworks { frameworks.append("Flask"); }
            if "sqlalchemy" in text and "SQLAlchemy" not in frameworks { frameworks.append("SQLAlchemy"); }
            if "pydantic" in text and "Pydantic" not in frameworks { frameworks.append("Pydantic"); }
            if "pytest" in text and "pytest" not in frameworks { frameworks.append("pytest"); }
        }

        if name == "gemfile" {
            text: str = read_file_head(full_path, content_cache);
            if "rails" in text and "Rails" not in frameworks { frameworks.append("Rails"); }
        }

        if lower.endswith(".scss") and "SCSS" not in frameworks { frameworks.append("SCSS"); }
        if lower.endswith(".vue") and "Vue" not in frameworks { frameworks.append("Vue"); }
        if lower.endswith(".svelte") and "Svelte" not in frameworks { frameworks.append("Svelte"); }
    }
    return frameworks;
}

def:pub scan_repo(repo_path: str) -> list[FileMatch] {
    matches: list[FileMatch] = [];
    if not repo_path {
        return matches;
    }

    effective_path: str = repo_path;
    cloned_tmp: str = "";

    if is_github_url(repo_path) {
        cloned_tmp = clone_github_repo(repo_path);
        if not cloned_tmp {
            return matches;
        }
        effective_path = cloned_tmp;
    } else {
        if not path.exists(repo_path) {
            return matches;
        }
    }

    try {
        for (current_root, dirs, files) in walk(effective_path) {
            kept_dirs: list[str] = [];
            for dir_name in dirs {
                if not should_skip_dir(dir_name) {
                    kept_dirs.append(dir_name);
                }
            }
            dirs.clear();
            for dir_name in kept_dirs {
                dirs.append(dir_name);
            }
            for file_name in files {
                if not should_include_file(file_name) {
                    continue;
                }
                full_path = path.join(current_root, file_name);
                rel_path: str = str(path.relpath(full_path, effective_path)).replace("\\", "/");
                matches.append(scored_match(rel_path, file_name));
            }
        }
    } except OSError {
        matches = [];
    }

    if cloned_tmp {
        rmtree(cloned_tmp, ignore_errors=True);
    }

    return matches;
}

def:pub summarize_repo(
    repo_path: str,
    scanned_files: list[FileMatch] | None = None,
    content_cache: dict[str, str] | None = None
) -> RepoSummary {
    files: list[FileMatch] = scanned_files if scanned_files is not None else scan_repo(repo_path);
    project_name: str = path.basename(repo_path) if repo_path else "Unknown Project";
    major_dirs: list[str] = [];
    entry_points: list[str] = [];

    for item in files {
        parts: list[str] = item.path.split("/");
        if len(parts) > 1 and parts[0] not in major_dirs {
            major_dirs.append(parts[0]);
        }
        if is_entry_point(parts[-1]) {
            entry_points.append(item.path);
        }
    }

    frameworks: list[str] = detect_frameworks(repo_path, files, content_cache);
    project_type: str = detect_project_type(repo_path, files, content_cache);

    framework_str: str = "";
    for fw in frameworks {
        if framework_str {
            framework_str = framework_str + ", ";
        }
        framework_str = framework_str + fw;
    }

    overview: str = project_type + " — " + str(len(files)) + " files scanned across " + str(len(major_dirs)) + " top-level directories.";
    if framework_str {
        overview = overview + " Stack: " + framework_str + ".";
    }

    return RepoSummary(
        project_name=project_name,
        overview=overview,
        frameworks=frameworks,
        entry_points=entry_points,
        major_dirs=major_dirs,
        project_type=project_type
    );
}
