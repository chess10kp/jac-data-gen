import re;
import time;
import html;
import socket;
import ipaddress;
import json;
import os;
import subprocess;
import from typing { cast }
import from datetime { datetime, timezone }
import from urllib.parse { urlparse, urljoin, urldefrag }
import from urllib.request { Request, build_opener, ProxyHandler }

import from services.models {
    UrlSafetyResult,
    PageFetchResult,
    CrawlResult,
    PageSnapshot,
    FlowStep,
    VisualSnapshot,
    InteractionStep,
    VisualAuditResult,
}

glob USER_AGENT = "EngagementAuditor/0.1 safe-prelaunch-crawler";
glob MAX_PAGE_BYTES = 650000;
glob MAX_REDIRECT_HINT = 10;

def dict_str(data: dict, key: str) -> str {
    if key in data {
        return str(data[key]);
    }
    return "";
}

def dict_int(data: dict, key: str) -> int {
    if key in data {
        try {
            return int(data[key]);
        } except Exception as e {
            return 0;
        }
    }
    return 0;
}

def dict_float(data: dict, key: str) -> float {
    if key in data {
        try {
            return float(str(data[key]));
        } except Exception as e {
            return 0.0;
        }
    }
    return 0.0;
}

def dict_list(data: dict, key: str) -> list[dict] {
    if key in data {
        return cast(list[dict], data[key]);
    }
    return [];
}

def now_iso() -> str {
    return datetime.now(timezone.utc).isoformat();
}

def normalize_space(value: str) -> str {
    return re.sub(r"\s+", " ", value).strip();
}

def safe_truncate(value: str, limit: int) -> str {
    cleaned: str = normalize_space(value);
    if len(cleaned) <= limit {
        return cleaned;
    }
    return cleaned[:limit].rstrip() + "...";
}

def host_is_blocked_name(host: str) -> bool {
    lowered: str = host.lower().strip(".");
    blocked_names: list[str] = [
        "localhost",
        "metadata.google.internal",
        "metadata",
        "host.docker.internal",
        "kubernetes.default.svc",
    ];
    if lowered in blocked_names {
        return True;
    }
    if lowered.endswith(".local") or lowered.endswith(".internal") {
        return True;
    }
    return False;
}

def ip_is_unsafe(ip_text: str) -> bool {
    try {
        ip_obj = ipaddress.ip_address(ip_text);
        if ip_obj.is_private or ip_obj.is_loopback or ip_obj.is_link_local {
            return True;
        }
        if ip_obj.is_multicast or ip_obj.is_reserved or ip_obj.is_unspecified {
            return True;
        }
        if ip_text == "169.254.169.254" {
            return True;
        }
    } except Exception as e {
        return True;
    }
    return False;
}

def host_resolves_safely(host: str) -> bool {
    if host_is_blocked_name(host) {
        return False;
    }
    try {
        infos = socket.getaddrinfo(host, None);
        if len(infos) == 0 {
            return False;
        }
        for info in infos {
            address: str = str(info[4][0]);
            if ip_is_unsafe(address) {
                return False;
            }
        }
    } except Exception as e {
        return False;
    }
    return True;
}

def validate_url_candidate(raw_url: str) -> UrlSafetyResult {
    candidate: str = raw_url.strip();
    if len(candidate) == 0 {
        return UrlSafetyResult(ok=False, final_url="", reason="Enter a URL to audit.");
    }
    if not (candidate.startswith("http://") or candidate.startswith("https://")) {
        return UrlSafetyResult(ok=False, final_url="", reason="Only http and https URLs can be audited.");
    }
    parsed = urlparse(candidate);
    if parsed.scheme not in ["http", "https"] {
        return UrlSafetyResult(ok=False, final_url="", reason="Only http and https URLs can be audited.");
    }
    if parsed.username or parsed.password {
        return UrlSafetyResult(ok=False, final_url="", reason="URLs containing credentials are rejected.");
    }
    if not parsed.hostname {
        return UrlSafetyResult(ok=False, final_url="", reason="The URL must include a valid host.");
    }
    if not host_resolves_safely(parsed.hostname) {
        return UrlSafetyResult(ok=False, final_url="", reason="Unsafe host: localhost, private networks, metadata IPs, and internal addresses are blocked.");
    }
    clean_url: str = str(urldefrag(candidate)[0]);
    return UrlSafetyResult(ok=True, final_url=clean_url, reason="ok");
}

def fetch_url_once(url: str) -> PageFetchResult {
    safety: UrlSafetyResult = validate_url_candidate(url);
    if not safety.ok {
        return PageFetchResult(ok=False, final_url=url, status_code=0, html_text="", content_type="", reason=safety.reason);
    }
    try {
        request = Request(
            safety.final_url,
            headers={
                "User-Agent": USER_AGENT,
                "Accept": "text/html,application/xhtml+xml;q=0.9,*/*;q=0.2",
            },
        );
        opener = build_opener(ProxyHandler({}));
        response = opener.open(request, timeout=8);
        final_url: str = str(response.geturl());
        final_safety: UrlSafetyResult = validate_url_candidate(final_url);
        if not final_safety.ok {
            return PageFetchResult(ok=False, final_url=final_url, status_code=0, html_text="", content_type="", reason="Redirected to an unsafe URL.");
        }
        content_type: str = str(response.headers.get("Content-Type", "")).lower();
        if "text/html" not in content_type and "application/xhtml" not in content_type {
            return PageFetchResult(ok=False, final_url=final_url, status_code=int(response.status), html_text="", content_type=content_type, reason="Only HTML pages are audited.");
        }
        length_header: str = str(response.headers.get("Content-Length", "0"));
        content_length: int = 0;
        try {
            content_length = int(length_header);
        } except Exception as e {
            content_length = 0;
        }
        if content_length > MAX_PAGE_BYTES {
            return PageFetchResult(ok=False, final_url=final_url, status_code=int(response.status), html_text="", content_type=content_type, reason="Page is oversized for the safe audit budget.");
        }
        data: bytes = bytes(response.read(MAX_PAGE_BYTES + 1));
        if len(data) > MAX_PAGE_BYTES {
            return PageFetchResult(ok=False, final_url=final_url, status_code=int(response.status), html_text="", content_type=content_type, reason="Page is oversized for the safe audit budget.");
        }
        body: str = bytes(data).decode("utf-8", "ignore");
        return PageFetchResult(ok=True, final_url=final_safety.final_url, status_code=int(response.status), html_text=body, content_type=content_type, reason="ok");
    } except Exception as e {
        return PageFetchResult(ok=False, final_url=url, status_code=0, html_text="", content_type="", reason=f"Could not fetch the page safely: {e}");
    }
}

def strip_unsafe_blocks(raw_html: str) -> str {
    cleaned: str = re.sub(r"(?is)<(script|style|svg|canvas|iframe|object|embed|noscript|template)[^>]*>.*?</\1>", " ", raw_html);
    cleaned = re.sub(r"(?is)<!--.*?-->", " ", cleaned);
    cleaned = re.sub(r"(?is)<form[^>]*>.*?</form>", " [form omitted: raw values not stored] ", cleaned);
    return cleaned;
}

def strip_tags(raw_html: str) -> str {
    cleaned: str = strip_unsafe_blocks(raw_html);
    cleaned = re.sub(r"(?is)<[^>]+>", " ", cleaned);
    return normalize_space(html.unescape(cleaned));
}

def extract_title(raw_html: str) -> str {
    m = re.search(r"(?is)<title[^>]*>(.*?)</title>", raw_html);
    if m {
        return safe_truncate(html.unescape(m.group(1)), 140);
    }
    return "";
}

def extract_headings(raw_html: str) -> list[str] {
    headings: list[str] = [];
    for m in re.findall(r"(?is)<h[1-3][^>]*>(.*?)</h[1-3]>", raw_html) {
        m_str: str = str(m);
        text: str = safe_truncate(re.sub(r"(?is)<[^>]+>", " ", html.unescape(m_str)), 140);
        if len(text) > 0 and text not in headings {
            headings.append(text);
        }
        if len(headings) >= 8 {
            break;
        }
    }
    return headings;
}

def extract_ctas(raw_html: str) -> list[str] {
    ctas: list[str] = [];
    patterns: list[str] = [
        r"(?is)<button[^>]*>(.*?)</button>",
        r"(?is)<a[^>]*(?:class|role|aria-label)[^>]*>(.*?)</a>",
        r"(?is)<input[^>]*(?:type=['\"]?(submit|button)['\"]?)[^>]*(?:value=['\"]([^'\"]+)['\"])?[^>]*>",
    ];
    for pattern in patterns {
        for m in re.findall(pattern, raw_html) {
            text: str = "";
            if isinstance(m, tuple) {
                for piece in m {
                    piece_text: str = str(piece);
                    if len(piece_text) > len(text) {
                        text = piece_text;
                    }
                }
            } else {
                text = m;
            }
            cleaned: str = safe_truncate(re.sub(r"(?is)<[^>]+>", " ", html.unescape(text)), 96);
            if len(cleaned) > 0 and cleaned not in ctas {
                ctas.append(cleaned);
            }
            if len(ctas) >= 12 {
                return ctas;
            }
        }
    }
    return ctas;
}

def extract_links(raw_html: str, base_url: str) -> list[str] {
    links: list[str] = [];
    base = urlparse(base_url);
    for href in re.findall(r"(?is)<a[^>]+href=['\"]([^'\"]+)['\"]", raw_html) {
        href_str: str = str(href);
        lowered: str = href_str.lower().strip();
        if lowered.startswith("mailto:") or lowered.startswith("tel:") or lowered.startswith("javascript:") {
            continue;
        }
        absolute: str = str(urldefrag(str(urljoin(base_url, href_str)))[0]);
        parsed = urlparse(absolute);
        if parsed.scheme not in ["http", "https"] {
            continue;
        }
        if parsed.hostname != base.hostname {
            continue;
        }
        if absolute not in links {
            links.append(absolute);
        }
        if len(links) >= 32 {
            break;
        }
    }
    return links;
}

def count_inputs(raw_html: str) -> int {
    return len(re.findall(r"(?is)<(input|select|textarea)\b", raw_html));
}

def prompt_injection_notes(text: str) -> str {
    lowered: str = text.lower();
    indicators: list[str] = [
        "ignore previous instructions",
        "ignore all previous",
        "system prompt",
        "developer message",
        "you are chatgpt",
        "do not audit",
        "jailbreak",
    ];
    found: list[str] = [];
    for indicator in indicators {
        if indicator in lowered {
            found.append(indicator);
        }
    }
    if len(found) == 0 {
        return "";
    }
    return "Possible prompt-injection text observed and treated as untrusted evidence: " + ", ".join(found);
}

def build_snapshot(audit_id: str, url: str, raw_html: str) -> PageSnapshot {
    visible_text: str = strip_tags(raw_html);
    words: list[str] = visible_text.split(" ");
    return PageSnapshot(
        audit_id=audit_id,
        page_url=url,
        title=extract_title(raw_html),
        text_excerpt=safe_truncate(visible_text, 2600),
        headings=extract_headings(raw_html),
        ctas=extract_ctas(raw_html),
        form_count=len(re.findall(r"(?is)<form\b", raw_html)),
        input_count=count_inputs(raw_html),
        link_count=len(re.findall(r"(?is)<a\b", raw_html)),
        word_count=len(words),
        risk_notes=prompt_injection_notes(visible_text),
    );
}

def crawl_site(start_url: str, audit_id: str, max_pages: int = 5, max_depth: int = 1, time_budget_seconds: int = 18) -> CrawlResult {
    safety: UrlSafetyResult = validate_url_candidate(start_url);
    if not safety.ok {
        return CrawlResult(snapshots=[], flow_steps=[], summary="", blocked_reason=safety.reason);
    }
    snapshots: list[PageSnapshot] = [];
    flow_steps: list[FlowStep] = [];
    seen: list[str] = [];
    queue_urls: list[str] = [safety.final_url];
    queue_depths: list[int] = [0];
    started: float = time.time();
    while len(queue_urls) > 0 and len(snapshots) < max_pages and (time.time() - started) < time_budget_seconds {
        current_url: str = queue_urls.pop(0);
        depth: int = queue_depths.pop(0);
        if current_url in seen {
            continue;
        }
        seen.append(current_url);
        fetched: PageFetchResult = fetch_url_once(current_url);
        if not fetched.ok {
            if len(snapshots) == 0 {
                return CrawlResult(snapshots=[], flow_steps=[], summary="", blocked_reason=fetched.reason);
            }
            continue;
        }
        snapshot: PageSnapshot = build_snapshot(audit_id, fetched.final_url, fetched.html_text);
        snapshots.append(snapshot);
        step_type: str = "landing";
        if depth > 0 {
            step_type = "linked page";
        }
        friction: int = min(100, snapshot.input_count * 7 + snapshot.form_count * 16 + max(0, 24 - len(snapshot.ctas)) // 2);
        flow_steps.append(FlowStep(
            audit_id=audit_id,
            step_order=len(flow_steps) + 1,
            page_url=fetched.final_url,
            step_type=step_type,
            friction_score=friction,
            evidence=f"{snapshot.title} | {len(snapshot.ctas)} CTA candidates | {snapshot.form_count} forms | {snapshot.input_count} inputs",
        ));
        if depth < max_depth {
            for link in extract_links(fetched.html_text, fetched.final_url) {
                if link not in seen and len(queue_urls) < (max_pages * 4) {
                    link_safety: UrlSafetyResult = validate_url_candidate(link);
                    if link_safety.ok {
                        queue_urls.append(link_safety.final_url);
                        queue_depths.append(depth + 1);
                    }
                }
            }
        }
    }
    if len(snapshots) == 0 {
        return CrawlResult(snapshots=[], flow_steps=[], summary="", blocked_reason="No safe HTML pages were captured.");
    }
    return CrawlResult(
        snapshots=snapshots,
        flow_steps=flow_steps,
        summary=f"Captured {len(snapshots)} safe HTML page snapshots within a {time_budget_seconds}s budget. Raw forms, credentials, scripts, and sensitive field values were not stored.",
        blocked_reason="",
    );
}

def run_visual_audit(start_url: str, audit_id: str, max_clicks: int = 8) -> VisualAuditResult {
    script_path: str = os.path.join(os.getcwd(), "tools", "visual_audit.py");
    output_dir: str = os.path.join(os.getcwd(), ".jac", "data", "visual");
    if not os.path.exists(script_path) {
        return VisualAuditResult(ok=False, summary="", blocked_reason="Visual audit helper script was not found.", visual_score=0, interaction_score=0, screenshots=[], interactions=[]);
    }
    try {
        result = subprocess.run(
            ["python", script_path, "--url", start_url, "--audit-id", audit_id, "--output-dir", output_dir, "--max-clicks", str(max_clicks)],
            capture_output=True,
            text=True,
            timeout=70,
        );
        if result.returncode != 0 {
            return VisualAuditResult(ok=False, summary="", blocked_reason=str(result.stderr), visual_score=0, interaction_score=0, screenshots=[], interactions=[]);
        }
        data: dict = cast(dict, json.loads(str(result.stdout)));
        if not bool(data["ok"]) {
            return VisualAuditResult(ok=False, summary="", blocked_reason=dict_str(data, "reason"), visual_score=0, interaction_score=0, screenshots=[], interactions=[]);
        }
        screenshots: list[VisualSnapshot] = [];
        for row in dict_list(data, "screenshots") {
            screenshots.append(VisualSnapshot(
                audit_id=audit_id,
                page_url=dict_str(row, "url"),
                title=dict_str(row, "title"),
                action_label=dict_str(row, "action_label"),
                screenshot_path=dict_str(row, "screenshot_path"),
                screenshot_data_url=dict_str(row, "screenshot_data_url"),
                viewport_width=dict_int(row, "width"),
                viewport_height=dict_int(row, "height"),
                brightness=dict_float(row, "brightness"),
                color_variance=dict_float(row, "color_variance"),
                visual_complexity=dict_float(row, "visual_complexity"),
                clickable_count=dict_int(row, "clickable_count"),
                psychology_rank=dict_str(row, "psychology_rank"),
                psychology_score=dict_int(row, "psychology_score"),
                visual_notes=dict_str(row, "visual_notes"),
            ));
        }
        interactions: list[InteractionStep] = [];
        for row in dict_list(data, "interactions") {
            interactions.append(InteractionStep(
                audit_id=audit_id,
                step_order=dict_int(row, "step_order"),
                element_label=dict_str(row, "element_label"),
                element_tag=dict_str(row, "element_tag"),
                from_url=dict_str(row, "from_url"),
                to_url=dict_str(row, "to_url"),
                result=dict_str(row, "result"),
                screenshot_path=dict_str(row, "screenshot_path"),
                psychology_rank=dict_str(row, "psychology_rank"),
                psychology_score=dict_int(row, "psychology_score"),
                visual_notes=dict_str(row, "visual_notes"),
                friction_score=dict_int(row, "friction_score"),
            ));
        }
        return VisualAuditResult(
            ok=True,
            summary=dict_str(data, "summary"),
            blocked_reason="",
            visual_score=dict_int(data, "visual_score"),
            interaction_score=dict_int(data, "interaction_score"),
            screenshots=screenshots,
            interactions=interactions,
        );
    } except Exception as e {
        return VisualAuditResult(ok=False, summary="", blocked_reason="Visual audit failed safely: " + str(e), visual_score=0, interaction_score=0, screenshots=[], interactions=[]);
    }
}
