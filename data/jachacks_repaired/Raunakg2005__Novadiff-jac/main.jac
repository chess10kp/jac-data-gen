"""
DiffMind — Jac Backend (main.jac)
Nodes + Git helpers + 8 public walkers with by llm() AI agents
Run:  jac start main.jac
"""

import dotenv;
import subprocess;
import os;
import hashlib;
import datetime;


# ─── Global Config ────────────────────────────────────────────────────────────

glob REPO_PATH: str = ".";

with entry {
    try {
        dotenv.load_dotenv();
    } except Exception as e {}
    REPO_PATH = os.environ.get("DIFF_REPO_PATH", ".");
}


# ─── Data Model (Graph Nodes) ─────────────────────────────────────────────────

node RepoDiffGraph {
    has repo_path: str = "";
    has last_hash: str = "";
    has last_updated: str = "";
}

node DiffFile {
    has file_path: str = "";
    has diff_content: str = "";
    has is_staged: bool = False;
    has language: str = "unknown";
    has additions: int = 0;
    has deletions: int = 0;
}

node Finding {
    has category: str = "";
    has severity: str = "warning";
    has title: str = "";
    has description: str = "";
    has file_path: str = "";
}

node QuizQuestion {
    has id: str = "";
    has prompt: str = "";
    has options: list[str] = [];
    has answerIndex: int = 0;
    has explanation: str = "";
}

node QuizNode {
    has questions: list[QuizQuestion] = [];
    has diff_hash: str = "";
    has passed: bool = False;
}

node CommitSuggestion {
    has message: str = "";
    has style: str = "conventional";
}


# ─── Git + Utility Helpers ────────────────────────────────────────────────────

def run_git(args: list[str]) -> dict {
    try {
        result = subprocess.run(
            ["git"] + args,
            cwd=REPO_PATH,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace"
        );
        ok: bool = result.returncode == 0;
        out: dict = {"stdout": result.stdout, "stderr": result.stderr, "ok": ok};
        return out;
    } except Exception as e {
        err_out: dict = {"stdout": "", "stderr": str(e), "ok": False};
        return err_out;
    }
}

def detect_language(file_path: str) -> str {
    if file_path.endswith(".py")   { return "python"; }
    elif file_path.endswith(".ts") { return "typescript"; }
    elif file_path.endswith(".tsx"){ return "tsx"; }
    elif file_path.endswith(".js") { return "javascript"; }
    elif file_path.endswith(".jsx"){ return "jsx"; }
    elif file_path.endswith(".go") { return "go"; }
    elif file_path.endswith(".rs") { return "rust"; }
    elif file_path.endswith(".java"){ return "java"; }
    elif file_path.endswith(".cpp"){ return "cpp"; }
    elif file_path.endswith(".c")  { return "c"; }
    elif file_path.endswith(".cs") { return "csharp"; }
    elif file_path.endswith(".rb") { return "ruby"; }
    elif file_path.endswith(".jac"){ return "jac"; }
    elif file_path.endswith(".json"){ return "json"; }
    elif file_path.endswith(".yaml") or file_path.endswith(".yml") { return "yaml"; }
    elif file_path.endswith(".md") { return "markdown"; }
    elif file_path.endswith(".html"){ return "html"; }
    elif file_path.endswith(".css"){ return "css"; }
    elif file_path.endswith(".sh") { return "bash"; }
    elif file_path.endswith(".kt") { return "kotlin"; }
    return "text";
}

def parse_diff_files(diff_output: str, staged: bool) -> list[dict] {
    files: list[dict] = [];
    current_file: dict = {};
    current_lines: list[str] = [];

    for line in diff_output.split("\n") {
        if line.startswith("diff --git") {
            if current_file {
                current_file["diff_content"] = "\n".join(current_lines);
                files.append(current_file);
            }
            parts = line.split(" b/");
            file_path = parts[-1].strip() if len(parts) > 1 else "unknown";
            current_file = {
                "file_path": file_path,
                "diff_content": "",
                "is_staged": staged,
                "language": detect_language(file_path),
                "additions": 0,
                "deletions": 0
            };
            current_lines = [line];
        } elif current_file {
            current_lines.append(line);
            if line.startswith("+") and not line.startswith("+++") {
                current_file["additions"] = current_file["additions"] + 1;
            } elif line.startswith("-") and not line.startswith("---") {
                current_file["deletions"] = current_file["deletions"] + 1;
            }
        }
    }
    if current_file and current_lines {
        current_file["diff_content"] = "\n".join(current_lines);
        files.append(current_file);
    }
    return files;
}

def compute_hash(text: str) -> str {
    return hashlib.md5(text.encode()).hexdigest()[:12];
}


# ─── Walker: GetDiffs ─────────────────────────────────────────────────────────

walker:pub GetDiffs {
    can run with entry {
        staged_r = run_git(["diff", "--no-color", "--cached"]);
        unstaged_r = run_git(["diff", "--no-color"]);
        staged_raw = staged_r["stdout"];
        unstaged_raw = unstaged_r["stdout"];
        full_diff = staged_raw + unstaged_raw;
        diff_hash = compute_hash(full_diff);
        res: dict = {
            "staged": parse_diff_files(staged_raw, True),
            "unstaged": parse_diff_files(unstaged_raw, False),
            "full_diff": full_diff,
            "diff_hash": diff_hash,
            "repo_path": REPO_PATH,
            "updated_at": datetime.datetime.now().isoformat()
        };
        report res;
    }
}


# ─── Walkers: Git Actions ─────────────────────────────────────────────────────

walker:pub StageFile {
    has file_path: str = "";
    can run with entry {
        r = run_git(["add", self.file_path]);
        res: dict = {"ok": r["ok"], "error": r["stderr"]};
        report res;
    }
}

walker:pub UnstageFile {
    has file_path: str = "";
    can run with entry {
        r = run_git(["reset", "HEAD", self.file_path]);
        res: dict = {"ok": r["ok"], "error": r["stderr"]};
        report res;
    }
}

walker:pub CommitChanges {
    has message: str = "";
    can run with entry {
        r = run_git(["commit", "-m", self.message]);
        res: dict = {"ok": r["ok"], "output": r["stdout"], "error": r["stderr"]};
        report res;
    }
}

walker:pub PushChanges {
    can run with entry {
        r = run_git(["push"]);
        res: dict = {"ok": r["ok"], "output": r["stdout"], "error": r["stderr"]};
        report res;
    }
}

walker:pub StashChanges {
    can run with entry {
        r = run_git(["stash"]);
        res: dict = {"ok": r["ok"], "output": r["stdout"]};
        report res;
    }
}


# ─── Walker: BugHunterAgent ───────────────────────────────────────────────────

walker:pub BugHunterAgent {
    has diff: str = "";
    has repo: str = "";

    """Analyze a git diff and return a list of software bug findings.
    You are a Bug Hunter agent specializing in code defect detection.
    Look for: logic errors, null or undefined reference risks, off-by-one errors,
    async race conditions, resource leaks, unhandled exceptions, missing edge cases.
    Each finding must be a dict with keys: severity (critical|warning|suggestion),
    title (short string), description (detailed actionable string).
    Return an empty list if no bugs are found."""
    def find_bugs_in_diff(
        git_diff_content: str,
        repository_context: str
    ) -> list[Finding] by llm();

    can run with entry {
        findings = self.find_bugs_in_diff(
            git_diff_content=self.diff,
            repository_context=self.repo
        );
        res: dict = {"category": "bug", "findings": findings};
        report res;
    }
}


# ─── Walker: SecurityAgent ────────────────────────────────────────────────────

walker:pub SecurityAgent {
    has diff: str = "";
    has repo: str = "";

    """Analyze a git diff and return a list of security vulnerability findings.
    You are a Security Analysis agent. Scan for OWASP Top 10 issues including:
    SQL injection, XSS, hardcoded secrets or API keys, insecure authentication,
    path traversal, command injection, insecure deserialization, improper input validation.
    Each finding must be a dict with keys: severity (critical|warning|suggestion),
    title (short string), description (detailed actionable string).
    Return an empty list if no vulnerabilities are found."""
    def find_security_issues_in_diff(
        git_diff_content: str,
        repository_context: str
    ) -> list[Finding] by llm();

    can run with entry {
        findings = self.find_security_issues_in_diff(
            git_diff_content=self.diff,
            repository_context=self.repo
        );
        res: dict = {"category": "security", "findings": findings};
        report res;
    }
}


# ─── Walker: QualityAgent ────────────────────────────────────────────────────

walker:pub QualityAgent {
    has diff: str = "";
    has repo: str = "";

    """Analyze a git diff and return a list of code quality improvement findings.
    You are a Code Quality agent. Review for: poor readability, naming convention
    violations, DRY principle violations, SOLID principle issues, overly complex
    nested conditionals, missing documentation for complex logic, inconsistent style,
    performance anti-patterns, and opportunities to use better APIs or abstractions.
    Each finding must be a dict with keys: severity (critical|warning|suggestion),
    title (short string), description (detailed actionable string).
    Return an empty list if the code quality is good."""
    def find_quality_issues_in_diff(
        git_diff_content: str,
        repository_context: str
    ) -> list[Finding] by llm();

    can run with entry {
        findings = self.find_quality_issues_in_diff(
            git_diff_content=self.diff,
            repository_context=self.repo
        );
        res: dict = {"category": "quality", "findings": findings};
        report res;
    }
}


# ─── Walker: SummaryAgent ────────────────────────────────────────────────────

walker:pub SummaryAgent {
    has findings: list[Finding] = [];

    """Produce a concise 2-3 sentence summary of code review findings.
    You are a Code Review Summarizer aggregating results from multiple agents.
    Prioritize critical issues first, then warnings. Be direct and actionable.
    Write for a developer who needs to understand the key takeaways quickly."""
    def summarize_all_findings(
        all_findings_from_review_agents: list[Finding]
    ) -> str by llm();

    can run with entry {
        if not self.findings {
            clean: dict = {"summary": "No issues found. The code looks clean!"};
            report clean;
        } else {
            summary = self.summarize_all_findings(
                all_findings_from_review_agents=self.findings
            );
            res: dict = {"summary": summary};
            report res;
        }
    }
}


# ─── Walker: ExplainWalker ───────────────────────────────────────────────────

walker:pub ExplainWalker {
    has diff: str = "";
    has question: str = "What does this change do?";
    has tone: str = "balanced";
    has format_style: str = "bullets";

    """Answer a developer question about their git diff changes.
    You are DiffMind Explain, an expert code analyst.
    Use the specified response tone: concise (short), balanced (moderate), detailed (thorough).
    Use the specified response format: bullets (bullet points) or paragraphs (prose).
    Be precise, reference specific code lines when helpful, and highlight risks."""
    def explain_diff_changes(
        git_diff_content: str,
        developer_question: str,
        response_tone: str,
        response_format: str
    ) -> str by llm();

    can run with entry {
        answer = self.explain_diff_changes(
            git_diff_content=self.diff,
            developer_question=self.question,
            response_tone=self.tone,
            response_format=self.format_style
        );
        res: dict = {"answer": answer};
        report res;
    }
}


# ─── Walker: QuizWalker ──────────────────────────────────────────────────────

walker:pub QuizWalker {
    has diff: str = "";
    has count: int = 5;
    has difficulty: str = "medium";
    has focus: str = "comprehension";

    """Generate a multiple-choice comprehension quiz about git diff code changes.
    You are DiffMind Quiz, an educational code comprehension tool.
    Each question must be a dict with these exact keys:
    id (string like q1, q2), prompt (the question text),
    options (list of exactly 4 strings), answerIndex (integer 0-3),
    explanation (string explaining why the answer is correct).
    Generate questions that test real understanding of what changed and why.
    Vary difficulty based on the difficulty_level parameter."""
    def generate_comprehension_quiz(
        git_diff_content: str,
        number_of_questions: int,
        difficulty_level: str,
        focus_area: str
    ) -> list[QuizQuestion] by llm();

    can run with entry {
        questions = self.generate_comprehension_quiz(
            git_diff_content=self.diff,
            number_of_questions=self.count,
            difficulty_level=self.difficulty,
            focus_area=self.focus
        );
        res: dict = {"questions": questions, "count": len(questions)};
        report res;
    }
}


# ─── Walker: CommitWalker ────────────────────────────────────────────────────

walker:pub CommitWalker {
    has diff: str = "";
    has style: str = "conventional";
    has include_body: bool = False;

    """Generate a git commit message for the provided staged diff.
    You are DiffMind Commit, an expert at writing clear, accurate git commit messages.
    Style options: conventional (use feat/fix/chore/docs/refactor/test prefix),
    descriptive (plain English sentence describing what changed),
    simple (one short imperative line, no prefix).
    If include_body is True, add one blank line then a 2-3 sentence body paragraph.
    Return ONLY the commit message text, with no extra explanation or markdown."""
    def generate_commit_message_for_changes(
        staged_diff_content: str,
        commit_style: str,
        should_include_body: bool
    ) -> str by llm();

    can run with entry {
        log_r = run_git(["log", "--oneline", "-10"]);
        history = log_r["stdout"];
        full_context = self.diff;
        if history {
            full_context = self.diff + "\n\n# Recent commit history:\n" + history;
        }
        message = self.generate_commit_message_for_changes(
            staged_diff_content=full_context,
            commit_style=self.style,
            should_include_body=self.include_body
        );
        res: dict = {"message": message.strip()};
        report res;
    }
}
