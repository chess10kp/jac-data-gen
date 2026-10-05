"""Executive summary generation for investigation results."""

import from ..models.llm_config { routing_llm }
import from ..tools.summary_util { sanitize_executive_summary }

"""Write a concise executive summary (markdown) for a dependency security investigation.
Repository: {repo_url}
Packages scanned: {packages_scanned}
Vulnerable packages: {vulnerable_count}

Findings:
{findings_text}

Use short sections with ## headings. Be specific about the highest-risk packages and CVEs.
Write package names as plain text or inline code with backticks only (e.g. `jsonwebtoken@0.4.0`).
Never use markdown links, email links, or mailto: URLs for package names — no [name](url) syntax at all.
Mention exploitability when findings include production usage (e.g. CRITICAL exploitability on prod auth code).
Do not invent CVE IDs or versions not listed in the findings."""
def generate_executive_summary(
    repo_url: str,
    findings_text: str,
    packages_scanned: int,
    vulnerable_count: int
) -> str by llm(
    model=routing_llm,
    temperature=0.2,
    max_tokens=1024
);

def generate_executive_summary_safe(
    repo_url: str,
    findings_text: str,
    packages_scanned: int,
    vulnerable_count: int
) -> str {
    raw = generate_executive_summary(
        repo_url,
        findings_text,
        packages_scanned,
        vulnerable_count
    );
    return sanitize_executive_summary(raw);
}