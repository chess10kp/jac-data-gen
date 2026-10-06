"""
Experimental telemetry-first helper runtime.

Purpose:
- Keep the current helper runtime untouched while exploring a cleaner Jac-native design.
- Start from normalized browser observation and explicit page artifacts instead of raw text improvisation.
- Execute bounded read-only plan steps with honest structured outputs and per-step provenance.
"""

import sys;
import json;
import time;
import re;
import from html { unescape }
import from urllib.parse { urlparse }
import from jac.layers.trace_utils { read_trace }
import from jac.layers.helpers_v2_io {
    load_observation_input,
    load_sources_input,
    open_sources_input
}

glob OBSERVATION_SCHEMA: str = "helpers_v2/observation_snapshot";
glob SOURCE_SCHEMA: str = "helpers_v2/source_candidate";
glob PAGE_SCHEMA: str = "helpers_v2/page_artifact";
glob PLAN_SCHEMA: str = "helpers_v2/plan_execution";
glob OUTPUT_SCHEMA: str = "helpers_v2/final_output";
glob PARENT_HELPERS_CLI_COMMANDS: list[str] = [
    "create_helper",
    "list_helpers",
    "get_helper",
    "run_helper_once",
    "list_helper_runs",
    "get_helper_run"
];

"""R: Return a stable UTC timestamp string for runtime records.
M: Uses `gmtime()` plus `strftime()` so outputs sort and compare cleanly in tests.
E: Precision is seconds, which is enough for this read-only prototype.
"""
def timestamp_now() -> str {
    t: any = time.gmtime();
    return time.strftime("%Y-%m-%dT%H:%M:%SZ", t);
}

"""R: Bound arbitrary values into compact plain-text fields.
M: String-casts, trims whitespace, and truncates to a caller-provided maximum.
E: Empty-like inputs normalize to the empty string.
"""
def safe_text(value: any, max_len: int = 240) -> str {
    text: str = str(value or "").strip();
    if len(text) > max_len {
        return text[:max_len];
    }
    return text;
}

"""R: Keep nested payloads transport-safe without widening result size unexpectedly.
M: Recursively limits depth, list size, dict size, and string length while preserving primitives.
E: Unsupported objects degrade to bounded strings instead of raising.
"""
def sanitize_json_value(raw: any, depth: int = 4, max_items: int = 12, max_len: int = 220) -> any {
    if depth <= 0 {
        return safe_text(raw, max_len);
    }

    if isinstance(raw, dict) {
        normalized: dict[str, any] = {};
        count: int = 0;
        for key in raw {
            if count >= max_items {
                break;
            }
            normalized[safe_text(key, 80)] = sanitize_json_value(raw[key], depth - 1, max_items, max_len);
            count += 1;
        }
        return normalized;
    }

    if isinstance(raw, list) {
        normalized_list: list[any] = [];
        count: int = 0;
        for item in raw {
            if count >= max_items {
                break;
            }
            normalized_list.append(sanitize_json_value(item, depth - 1, max_items, max_len));
            count += 1;
        }
        return normalized_list;
    }

    if isinstance(raw, bool) or isinstance(raw, int) or isinstance(raw, float) {
        return raw;
    }

    return safe_text(raw, max_len);
}

"""R: Normalize list-like inputs into small unique string lists.
M: Iterates real lists only, trims items, skips blanks, and enforces uniqueness and bounds.
E: Non-list values return the empty list.
"""
def normalize_text_list(raw: any, max_items: int = 8, max_len: int = 180) -> list[str] {
    results: list[str] = [];
    if not isinstance(raw, list) {
        return results;
    }

    for item in raw {
        if len(results) >= max_items {
            break;
        }
        text: str = safe_text(item, max_len);
        if not text or text in results {
            continue;
        }
        results.append(text);
    }
    return results;
}

"""R: Add one unique bounded string into an accumulating text list.
M: Normalizes the incoming value and appends only if it is present and new.
E: Empty values are ignored silently.
"""
def add_unique_text(values: list[str], raw_value: any, max_len: int = 180) {
    text: str = safe_text(raw_value, max_len);
    if text and text not in values {
        values.append(text);
    }
}

"""R: Bound integer configuration values for plan and output controls.
M: Uses integer inputs when present, otherwise falls back, then clamps to the requested range.
E: Invalid and extreme values collapse to conservative defaults.
"""
def clamp_int_limit(raw_value: any, fallback: int, min_value: int, max_value: int) -> int {
    value: int = fallback;
    if isinstance(raw_value, int) and not isinstance(raw_value, bool) {
        value = raw_value;
    }
    if value < min_value {
        return min_value;
    }
    if value > max_value {
        return max_value;
    }
    return value;
}

"""R: Extract a normalized domain from a URL-like value for scoring and provenance.
M: Uses `urlparse` and strips a leading `www.` for stable comparisons.
E: Invalid or blank URLs return the empty string.
"""
def domain_from_url(raw_url: any) -> str {
    url_value: str = safe_text(raw_url, 500);
    if not url_value {
        return "";
    }

    try {
        parsed: any = urlparse(url_value);
        host: str = safe_text(parsed.netloc or "", 180).lower();
        if host.startswith("www.") {
            return host[4:];
        }
        return host;
    } except ValueError {
        return "";
    }
}

def url_path(raw_url: any) -> str {
    url_value: str = safe_text(raw_url, 500);
    if not url_value {
        return "";
    }

    try {
        parsed: any = urlparse(url_value);
        return safe_text(parsed.path or "/", 260).lower();
    } except ValueError {
        return "";
    }
}

def path_segments(raw_url: any) -> list[str] {
    segments: list[str] = [];
    for segment in url_path(raw_url).split("/") {
        cleaned: str = safe_text(segment, 120).strip();
        if cleaned {
            segments.append(cleaned);
        }
    }
    return segments;
}

def path_has_date_signal(raw_url: any) -> bool {
    return re.search(r"/20\d{2}/\d{1,2}/\d{1,2}(?:/|$)", url_path(raw_url)) is not None;
}

"""R: Detect hub-like paths that usually represent index, topic, or landing pages.
M: Checks for shallow paths, known section markers, and generic topic-style slugs.
E: Paths with date-like article structure are treated as non-hub even when they contain topic words.
"""
def url_looks_hub_like(raw_url: any) -> bool {
    path_value: str = url_path(raw_url);
    if not path_value or path_value == "/" {
        return True;
    }
    if path_has_date_signal(raw_url) {
        return False;
    }

    if path_value in [
        "/news",
        "/news/",
        "/latest",
        "/latest/",
        "/topic",
        "/topic/",
        "/topics",
        "/topics/",
        "/category",
        "/category/",
        "/categories",
        "/categories/",
        "/archive",
        "/archive/",
        "/ai",
        "/ai/"
    ] {
        return True;
    }

    segments: list[str] = path_segments(raw_url);
    if len(segments) == 2 and segments[0] == "news" {
        second_segment: str = segments[1];
        if "-" in second_segment and len(second_segment) >= 14 {
            return False;
        }
    }
    if len(segments) <= 2 {
        for segment in segments {
            if segment in ["news", "latest", "topic", "topics", "category", "categories", "archive", "ai"] {
                return True;
            }
        }
    }

    if len(segments) > 0 {
        last_segment: str = segments[len(segments) - 1];
        if re.search(r"^(latest[-_].*(news|updates)|.*news[-_]and[-_]updates|artificial-intelligence|machine-learning)$", last_segment) {
            return True;
        }
    }
    return False;
}

"""R: Detect article-shaped URLs so source scoring can reward concrete reporting pages.
M: Looks for date signals, deeper paths, story/article markers, and descriptive slugs.
E: Hub-like URLs stay non-article even if they have long path text.
"""
def url_looks_article_like(raw_url: any) -> bool {
    if url_looks_hub_like(raw_url) {
        return False;
    }

    path_value: str = url_path(raw_url);
    segments: list[str] = path_segments(raw_url);
    if path_has_date_signal(raw_url) {
        return True;
    }
    if "/article/" in path_value or "/story/" in path_value {
        return True;
    }
    if len(segments) >= 3 {
        return True;
    }
    if len(segments) > 0 and "-" in segments[len(segments) - 1] and len(segments[len(segments) - 1]) >= 14 {
        return True;
    }
    return False;
}

"""R: Detect generic hub titles that should not drive synthesis quality.
M: Normalizes punctuation and matches a compact set of recurring generic title patterns.
E: Specific event headlines are allowed through even when they contain the word `news`.
"""
def title_looks_hub_like(raw_title: any) -> bool {
    title_value: str = safe_text(raw_title, 240).lower();
    if not title_value {
        return False;
    }

    normalized: str = re.sub(r"[^a-z0-9\s]", " ", title_value);
    normalized = " ".join(normalized.split());
    if normalized in [
        "ai news",
        "latest ai news",
        "artificial intelligence news",
        "latest updates",
        "news"
    ] {
        return True;
    }

    if re.search(r"^(ai news|latest ai news|artificial intelligence news)(?:\s*[:|\-].*)?$", title_value) {
        if not re.search(r"\b(openai|meta|google|anthropic|microsoft|amazon|nvidia|launch|release|update|deal|lawsuit|pricing)\b", title_value) {
            return True;
        }
    }
    return False;
}

"""R: Detect specificity signals that separate reporting content from generic hub or marketing copy.
M: Looks for named entities, reporting verbs, enterprise/product terms, and year/version markers.
E: Generic “latest updates” language without concrete signals returns False.
"""
def text_has_specificity_signals(raw_text: any) -> bool {
    text_value: str = safe_text(raw_text, 360).lower();
    if not text_value {
        return False;
    }

    if re.search(
        r"\b(openai|meta|google|anthropic|microsoft|amazon|nvidia|xai|claude|gemini|gpt|llama|enterprise|multimodal|deployment|regulator|funding|pricing)\b",
        text_value
    ) {
        return True;
    }
    if re.search(
        r"\b(announced|launch|launched|release|released|updated|ships|expand|expanded|raises|raised|funding|probe|lawsuit|controls|guardrails|clusters)\b",
        text_value
    ) {
        return True;
    }
    if re.search(r"\b20\d{2}\b", text_value) {
        return True;
    }
    return False;
}

def text_looks_marketing(raw_text: any) -> bool {
    text_value: str = safe_text(raw_text, 360).lower();
    if not text_value {
        return False;
    }
    return re.search(
        r"\b(book a demo|request a demo|contact sales|trusted by|platform for|transform your business|why choose us|get started)\b",
        text_value
    ) is not None;
}

"""R: Strip noisy HTML payloads into readable bounded text for page artifacts.
M: Removes comments and embedded/script-like blocks, converts common structural tags to spaces, strips tags, and collapses whitespace.
E: Empty or malformed HTML returns the empty string rather than partial markup.
"""
def clean_html_text(raw_html: any, max_len: int = 900) -> str {
    html_text: str = str(raw_html or "");
    if not html_text {
        return "";
    }

    cleaned: str = re.sub("<!--.*?-->", " ", html_text, flags=re.DOTALL);
    for tag_name in ["script", "style", "noscript", "svg", "iframe"] {
        cleaned = re.sub(
            "<" + tag_name + r"\b[^>]*>.*?</" + tag_name + ">",
            " ",
            cleaned,
            flags=re.IGNORECASE | re.DOTALL
        );
    }
    cleaned = re.sub(r"</?(article|section|main|p|h1|h2|h3|li|div|br)[^>]*>", " ", cleaned, flags=re.IGNORECASE);
    cleaned = re.sub(r"<[^>]+>", " ", cleaned);
    cleaned = unescape(cleaned);
    cleaned = " ".join(cleaned.split());
    return safe_text(cleaned, max_len);
}

"""R: Decide whether text is substantive enough to support bounded synthesis.
M: Requires a minimum word count, alphabetic density, and at least one sentence-like delimiter or sufficient length.
E: Titles and very short snippets return False so the runtime does not synthesize from shell text.
"""
def text_is_substantive(raw_text: any) -> bool {
    text_value: str = " ".join(str(raw_text or "").split());
    if not text_value {
        return False;
    }

    alpha_chars: any = re.findall(r"[A-Za-z]", text_value);
    words: any = re.findall(r"[A-Za-z0-9][A-Za-z0-9\-]*", text_value);
    if len(alpha_chars) < 24 or len(words) < 8 {
        return False;
    }
    if not re.search(r"[.!?]", text_value) and len(words) < 14 {
        return False;
    }
    return True;
}

"""R: Turn the latest trace or browser hint into one explicit normalized observation snapshot.
M: Reuses the repo’s telemetry seams, preserves bounded headings/actions/links/forms, and records provenance.
E: Missing trace data still returns a stable empty observation instead of raising or fabricating detail.
"""
def normalize_observation_snapshot(trace_data: dict[str, any], browser_hint: any = None) -> dict[str, any] {
    semantic: dict[str, any] = {};
    dom_snapshot: dict[str, any] = {};
    session_state: dict[str, any] = {};
    if isinstance(trace_data.get("latest_semantic", {}), dict) {
        semantic = sanitize_json_value(trace_data.get("latest_semantic", {}), 4, 18, 220);
    }
    if isinstance(trace_data.get("latest_dom_snapshot", {}), dict) {
        dom_snapshot = sanitize_json_value(trace_data.get("latest_dom_snapshot", {}), 4, 18, 220);
    }
    if isinstance(trace_data.get("latest_session_state", {}), dict) {
        session_state = sanitize_json_value(trace_data.get("latest_session_state", {}), 4, 18, 220);
    }

    hint_url: str = "";
    hint_title: str = "";
    if isinstance(browser_hint, dict) {
        hint_url = safe_text(browser_hint.get("current_url", ""), 320);
        hint_title = safe_text(browser_hint.get("title", ""), 180);
    } else {
        browser_hint = {};
    }

    current_url: str = safe_text(trace_data.get("source_url", ""), 320) or hint_url;
    navigation_chain: list[str] = [];
    raw_events: any = trace_data.get("events", []);
    if isinstance(raw_events, list) {
        for event in raw_events {
            if not isinstance(event, dict) {
                continue;
            }
            event_type: str = safe_text(event.get("type", ""), 40);
            if event_type not in ["navigate", "page_ready", "tab_switched"] {
                continue;
            }
            event_url: str = safe_text(event.get("url", ""), 320);
            if not event_url {
                continue;
            }
            if len(navigation_chain) > 0 and navigation_chain[len(navigation_chain) - 1] == event_url {
                continue;
            }
            navigation_chain.append(event_url);
            if len(navigation_chain) > 6 {
                navigation_chain = navigation_chain[len(navigation_chain) - 6:];
            }
        }
    }
    if len(navigation_chain) > 0 {
        current_url = navigation_chain[len(navigation_chain) - 1];
    }

    title: str = safe_text(semantic.get("title", ""), 180);
    if not title {
        title = safe_text(dom_snapshot.get("title", ""), 180);
    }
    if not title {
        title = hint_title;
    }

    headings: list[str] = normalize_text_list(dom_snapshot.get("headings", []), 8, 140);
    for heading in normalize_text_list(semantic.get("headings", []), 8, 140) {
        add_unique_text(headings, heading, 140);
    }

    text_blocks: list[str] = [];
    add_unique_text(text_blocks, dom_snapshot.get("body_text_sample", ""), 260);
    for heading in headings {
        add_unique_text(text_blocks, heading, 140);
    }

    actions: list[any] = [];
    for label in normalize_text_list(semantic.get("primary_actions", []), 8, 120) {
        actions.append({"label": label, "kind": "semantic"});
    }
    raw_buttons: any = dom_snapshot.get("buttons", []);
    if isinstance(raw_buttons, list) {
        for button in raw_buttons {
            if len(actions) >= 8 {
                break;
            }
            if not isinstance(button, dict) {
                continue;
            }
            label: str = safe_text(button.get("label", ""), 120) or safe_text(button.get("text", ""), 120);
            if not label {
                continue;
            }
            actions.append({
                "label": label,
                "kind": "button",
                "path": safe_text(button.get("path", ""), 220)
            });
        }
    }

    links: list[any] = [];
    raw_links: any = dom_snapshot.get("links", []);
    if isinstance(raw_links, list) {
        for link in raw_links {
            if len(links) >= 8 {
                break;
            }
            if not isinstance(link, dict) {
                continue;
            }
            href: str = safe_text(link.get("href", ""), 500);
            title_text: str = safe_text(link.get("text", ""), 160);
            if not href and not title_text {
                continue;
            }
            links.append({
                "href": href,
                "text": title_text,
                "domain": domain_from_url(href),
                "path": safe_text(link.get("path", ""), 220),
                "origin": "observation"
            });
        }
    }

    forms: list[any] = [];
    raw_forms: any = dom_snapshot.get("forms", []);
    if isinstance(raw_forms, list) {
        for form in raw_forms {
            if len(forms) >= 6 {
                break;
            }
            if not isinstance(form, dict) {
                continue;
            }
            forms.append({
                "method": safe_text(form.get("method", ""), 12),
                "action": safe_text(form.get("action", ""), 320),
                "field_count": form.get("field_count", 0) if isinstance(form.get("field_count", 0), int) else 0,
                "submit_text": safe_text(form.get("submit_text", ""), 120),
                "labels": normalize_text_list(form.get("labels", []), 8, 120),
                "path": safe_text(form.get("path", ""), 220)
            });
        }
    }

    page_summary_parts: list[str] = [];
    if title {
        page_summary_parts.append("Title: " + title);
    }
    if len(text_blocks) > 0 {
        page_summary_parts.append("Content: " + safe_text(text_blocks[0], 180));
    }
    if len(actions) > 0 and isinstance(actions[0], dict) {
        page_summary_parts.append("Primary action: " + safe_text(actions[0].get("label", ""), 120));
    }

    page_summary: str = "No current browser observation is available.";
    if len(page_summary_parts) > 0 {
        page_summary = ". ".join(page_summary_parts);
    }

    source_kind: str = "none";
    if trace_data {
        source_kind = "trace";
    } elif isinstance(browser_hint, dict) and len(browser_hint) > 0 {
        source_kind = "hint";
    }

    observed_at: str = safe_text(trace_data.get("updated_at", ""), 40) or timestamp_now();
    if isinstance(raw_events, list) and len(raw_events) > 0 and isinstance(raw_events[len(raw_events) - 1], dict) {
        observed_at = safe_text(raw_events[len(raw_events) - 1].get("recorded_at", ""), 40) or observed_at;
    }

    current_domain: str = domain_from_url(current_url);
    return {
        "schema": OBSERVATION_SCHEMA,
        "observation_id": "obs_" + str(int(time.time() * 1000)),
        "source_session_id": safe_text(trace_data.get("session_id", ""), 120),
        "source_kind": source_kind,
        "observed_at": observed_at,
        "page": {
            "url": current_url,
            "title": title,
            "domain": current_domain,
            "page_kind": safe_text(semantic.get("page_kind", ""), 40),
            "workflow_stage": safe_text(semantic.get("workflow_stage", ""), 40),
            "page_summary": safe_text(page_summary, 320)
        },
        "telemetry": {
            "counts": sanitize_json_value(trace_data.get("telemetry_counts", {}), 3, 16, 120),
            "recent_navigation_chain": navigation_chain,
            "session_state": session_state
        },
        "signals": {
            "headings": headings,
            "text_blocks": text_blocks,
            "actions": sanitize_json_value(actions, 4, 8, 180),
            "links": sanitize_json_value(links, 4, 8, 220),
            "forms": sanitize_json_value(forms, 4, 6, 180)
        },
        "provenance": [
            {
                "kind": source_kind,
                "session_id": safe_text(trace_data.get("session_id", ""), 120),
                "url": current_url
            }
        ]
    };
}

"""R: Build one source-candidate contract from observation links or search results.
M: Normalizes common fields, assigns an origin, and keeps only bounded metadata needed for scoring.
E: Missing URL and title both produce a candidate with a blank identity that later scoring will reject.
"""
def normalize_source_candidate(raw_candidate: any, origin: str, index: int) -> dict[str, any] {
    candidate: dict[str, any] = {};
    if isinstance(raw_candidate, dict) {
        candidate = raw_candidate;
    }

    url_value: str = safe_text(candidate.get("href", ""), 500) or safe_text(candidate.get("url", ""), 500);
    title_value: str = safe_text(candidate.get("text", ""), 180) or safe_text(candidate.get("title", ""), 180);
    snippet_value: str = clean_html_text(candidate.get("snippet", ""), 240);
    return {
        "schema": SOURCE_SCHEMA,
        "candidate_id": "src_" + str(index),
        "origin": safe_text(origin, 40),
        "url": url_value,
        "title": title_value,
        "snippet": snippet_value,
        "domain": domain_from_url(url_value),
        "path": safe_text(candidate.get("path", ""), 220)
    };
}

"""R: Score one source candidate for article-likelihood and synthesis value.
M: Combines URL shape, title/snippet specificity, and hub penalties into a bounded score with explicit reasons.
E: Weak or generic sources still return a contract, but with low score and `weak` quality hints.
"""
def score_source_candidate(candidate: dict[str, any]) -> dict[str, any] {
    score: int = 0;
    reasons: list[str] = [];
    url_value: str = safe_text(candidate.get("url", ""), 500);
    title_value: str = safe_text(candidate.get("title", ""), 180);
    snippet_value: str = safe_text(candidate.get("snippet", ""), 240);

    if url_looks_article_like(url_value) {
        score += 35;
        reasons.append("article_like_url");
    }
    if path_has_date_signal(url_value) {
        score += 10;
        reasons.append("dated_path");
    }
    if text_has_specificity_signals(title_value) {
        score += 22;
        reasons.append("specific_title");
    }
    if text_has_specificity_signals(snippet_value) {
        score += 18;
        reasons.append("specific_snippet");
    }
    if url_looks_hub_like(url_value) {
        score -= 32;
        reasons.append("hub_like_url");
    }
    if title_looks_hub_like(title_value) {
        score -= 24;
        reasons.append("hub_like_title");
    }
    if text_looks_marketing(title_value + " " + snippet_value) {
        score -= 18;
        reasons.append("marketing_copy");
    }
    if not title_value and not snippet_value {
        score -= 12;
        reasons.append("sparse_metadata");
    }

    quality_hint: str = "weak";
    if score >= 45 {
        quality_hint = "strong";
    } elif score >= 18 {
        quality_hint = "usable";
    }

    page_shape: str = "unknown";
    if url_looks_article_like(url_value) {
        page_shape = "article_like";
    } elif url_looks_hub_like(url_value) {
        page_shape = "hub_like";
    }

    scored_candidate: dict[str, any] = sanitize_json_value(candidate, 4, 12, 220);
    scored_candidate["score"] = score;
    scored_candidate["quality_hint"] = quality_hint;
    scored_candidate["score_reasons"] = reasons;
    scored_candidate["page_shape"] = page_shape;
    return scored_candidate;
}

"""R: Rank available source candidates without requiring autonomous browsing behavior.
M: Normalizes observation/search candidates, scores each one, and returns a highest-score-first list with step metadata.
E: Empty inputs return a blocked-style payload rather than fabricated candidates.
"""
def score_source_candidates(search_results: any, observation_links: any, top_k: int = 5) -> dict[str, any] {
    normalized: list[any] = [];
    if isinstance(search_results, list) {
        index: int = 0;
        for item in search_results {
            normalized.append(normalize_source_candidate(item, "search_result", index));
            index += 1;
        }
    }
    if isinstance(observation_links, list) {
        index: int = len(normalized);
        for item in observation_links {
            normalized.append(normalize_source_candidate(item, "observation_link", index));
            index += 1;
        }
    }

    if len(normalized) == 0 {
        return {
            "status": "blocked",
            "reason": "no_source_candidates",
            "summary": "No source candidates were available from telemetry or injected search results.",
            "candidates": []
        };
    }

    scored: list[any] = [];
    for item in normalized {
        if not isinstance(item, dict) {
            continue;
        }
        scored.append(score_source_candidate(item));
    }

    ranked: list[any] = [];
    used_urls: list[str] = [];
    limit: int = clamp_int_limit(top_k, 5, 1, 8);
    while len(ranked) < limit {
        best_index: int = -1;
        best_score: int = -999;
        idx: int = 0;
        for item in scored {
            if not isinstance(item, dict) {
                idx += 1;
                continue;
            }
            candidate_url: str = safe_text(item.get("url", ""), 500);
            candidate_key: str = candidate_url or safe_text(item.get("title", ""), 180);
            if not candidate_key or candidate_key in used_urls {
                idx += 1;
                continue;
            }
            candidate_score: int = item.get("score", 0) if isinstance(item.get("score", 0), int) else 0;
            if best_index == -1 or candidate_score > best_score {
                best_index = idx;
                best_score = candidate_score;
            }
            idx += 1;
        }
        if best_index == -1 {
            break;
        }
        best_item: any = scored[best_index];
        ranked.append(best_item);
        if isinstance(best_item, dict) {
            used_urls.append(safe_text(best_item.get("url", ""), 500) or safe_text(best_item.get("title", ""), 180));
        }
    }

    return {
        "status": "success",
        "reason": "",
        "summary": "Scored source candidates from explicit telemetry and injected source inputs.",
        "candidates": ranked
    };
}

"""R: Convert one opened page or current-page observation into a bounded page-artifact contract.
M: Normalizes content/excerpt fields, preserves provenance, and keeps only read-only metadata needed for synthesis gating.
E: Missing text remains explicit so later classification can downgrade or refuse synthesis honestly.
"""
def normalize_page_artifact(raw_page: any, origin: str, index: int) -> dict[str, any] {
    page: dict[str, any] = {};
    if isinstance(raw_page, dict) {
        page = raw_page;
    }

    url_value: str = safe_text(page.get("url", ""), 500) or safe_text(page.get("href", ""), 500);
    excerpt: str = safe_text(page.get("content_excerpt", ""), 900);
    normalized_content: str = safe_text(page.get("normalized_content", ""), 2200);
    if not excerpt and normalized_content {
        excerpt = safe_text(normalized_content, 900);
    }
    if not excerpt and page.get("body", "") {
        excerpt = clean_html_text(page.get("body", ""), 900);
    }

    return {
        "schema": PAGE_SCHEMA,
        "artifact_id": "page_" + str(index),
        "origin": safe_text(origin, 40),
        "url": url_value,
        "title": safe_text(page.get("title", ""), 180) or safe_text(page.get("text", ""), 180),
        "domain": domain_from_url(url_value),
        "http_status": page.get("http_status", 200) if isinstance(page.get("http_status", 200), int) else 200,
        "content_type": safe_text(page.get("content_type", ""), 120),
        "excerpt": excerpt,
        "normalized_content": safe_text(normalized_content, 2200),
        "fetch_error": safe_text(page.get("fetch_error", ""), 180) or safe_text(page.get("error", ""), 180),
        "provenance": [
            {
                "kind": safe_text(origin, 40),
                "url": url_value
            }
        ]
    };
}

"""R: Classify a page artifact into synthesis-relevant classes instead of assuming every page is article-grade.
M: Uses HTTP status, excerpt substance, hub signals, and marketing cues to assign class, quality, and eligibility.
E: Weak pages still return a full contract, but with explicit limitations and ineligible synthesis status.
"""
def classify_page_artifact(page: dict[str, any]) -> dict[str, any] {
    classification: str = "article";
    quality: str = "strong";
    limitations: list[str] = [];
    synthesis_eligible: bool = True;

    http_status: int = page.get("http_status", 200) if isinstance(page.get("http_status", 200), int) else 200;
    url_value: str = safe_text(page.get("url", ""), 500);
    title_value: str = safe_text(page.get("title", ""), 180);
    excerpt_value: str = safe_text(page.get("excerpt", ""), 900);

    if http_status >= 400 or safe_text(page.get("fetch_error", ""), 180) {
        classification = "error_page";
        quality = "weak";
        synthesis_eligible = False;
        limitations.append("page_fetch_failed");
    } elif not text_is_substantive(excerpt_value) {
        classification = "low_content";
        quality = "weak";
        synthesis_eligible = False;
        limitations.append("excerpt_not_substantive");
    } elif text_looks_marketing(title_value + " " + excerpt_value) and not text_has_specificity_signals(excerpt_value) {
        classification = "marketing_page";
        quality = "weak";
        synthesis_eligible = False;
        limitations.append("marketing_or_promotional_copy");
    } elif url_looks_hub_like(url_value) or title_looks_hub_like(title_value) {
        classification = "hub";
        quality = "weak";
        synthesis_eligible = False;
        limitations.append("hub_or_index_content");
    } elif not text_has_specificity_signals(title_value + " " + excerpt_value) {
        quality = "usable";
        limitations.append("limited_specificity");
    }

    classified_page: dict[str, any] = sanitize_json_value(page, 4, 14, 220);
    classified_page["classification"] = classification;
    classified_page["quality"] = quality;
    classified_page["synthesis_eligible"] = synthesis_eligible;
    classified_page["limitations"] = limitations;
    return classified_page;
}

"""R: Promote the current observation into a page artifact so current-page tasks use the same synthesis pipeline as opened pages.
M: Builds one bounded excerpt from observation text blocks and page summary, then classifies it with the shared page rules.
E: Sparse observations become low-content artifacts rather than triggering fabricated summaries.
"""
def current_page_artifact_from_observation(observation: dict[str, any]) -> dict[str, any] {
    text_blocks: list[str] = [];
    if isinstance(observation.get("signals", {}).get("text_blocks", []), list) {
        text_blocks = observation.get("signals", {}).get("text_blocks", []);
    }

    excerpt_parts: list[str] = [];
    for block in text_blocks {
        if len(excerpt_parts) >= 2 {
            break;
        }
        add_unique_text(excerpt_parts, block, 220);
    }
    if len(excerpt_parts) == 0 {
        add_unique_text(excerpt_parts, observation.get("page", {}).get("page_summary", ""), 220);
    }

    page: dict[str, any] = normalize_page_artifact({
        "url": observation.get("page", {}).get("url", ""),
        "title": observation.get("page", {}).get("title", ""),
        "content_excerpt": ". ".join(excerpt_parts),
        "content_type": "telemetry_snapshot"
    }, "current_observation", 0);
    return classify_page_artifact(page);
}

"""R: Classify all injected opened pages into explicit extraction artifacts for later synthesis gating.
M: Normalizes each page first, then assigns page class, quality, and eligibility using shared heuristics.
E: Empty inputs return a blocked-style contract so callers can report a capability or data gap honestly.
"""
def classify_opened_pages(opened_pages: any) -> dict[str, any] {
    if not isinstance(opened_pages, list) or len(opened_pages) == 0 {
        return {
            "status": "blocked",
            "reason": "no_opened_pages",
            "summary": "No opened pages were provided to the read-only prototype.",
            "page_artifacts": []
        };
    }

    artifacts: list[any] = [];
    eligible_count: int = 0;
    hub_count: int = 0;
    for page in opened_pages {
        artifact: dict[str, any] = classify_page_artifact(normalize_page_artifact(page, "opened_page", len(artifacts)));
        if bool(artifact.get("synthesis_eligible", False)) {
            eligible_count += 1;
        }
        if safe_text(artifact.get("classification", ""), 40) == "hub" {
            hub_count += 1;
        }
        artifacts.append(artifact);
    }

    status: str = "success";
    if eligible_count == 0 {
        status = "partial";
    }

    return {
        "status": status,
        "reason": "",
        "summary": "Classified opened pages into explicit page artifacts.",
        "page_artifacts": artifacts,
        "eligible_count": eligible_count,
        "hub_count": hub_count
    };
}

"""R: Collect bounded supporting links from the current observation or classified page artifacts.
M: Prefers explicit browser links, then falls back to artifact URLs so later synthesis can emit concrete follow-ups.
E: Missing links stays partial instead of fabricating references from summary text.
"""
def collect_supporting_links(observation: any, page_artifacts: any, max_links: int = 5) -> dict[str, any] {
    links: list[any] = [];
    seen_urls: dict[str, bool] = {};

    if isinstance(observation, dict) and isinstance(observation.get("signals", {}).get("links", []), list) {
        for raw_link in observation.get("signals", {}).get("links", []) {
            if len(links) >= max_links or not isinstance(raw_link, dict) {
                continue;
            }
            href_value: str = safe_text(raw_link.get("href", ""), 500);
            if not href_value or bool(seen_urls.get(href_value, False)) {
                continue;
            }
            seen_urls[href_value] = True;
            links.append({
                "url": href_value,
                "title": safe_text(raw_link.get("text", ""), 180) or safe_text(raw_link.get("label", ""), 180) or href_value,
                "classification": "supporting_link",
                "quality": "reference"
            });
        }
    }

    if isinstance(page_artifacts, list) {
        for artifact in page_artifacts {
            if len(links) >= max_links or not isinstance(artifact, dict) {
                continue;
            }
            artifact_url: str = safe_text(artifact.get("url", ""), 500);
            if not artifact_url or bool(seen_urls.get(artifact_url, False)) {
                continue;
            }
            seen_urls[artifact_url] = True;
            links.append({
                "url": artifact_url,
                "title": safe_text(artifact.get("title", ""), 180) or artifact_url,
                "classification": safe_text(artifact.get("classification", ""), 40) or "supporting_link",
                "quality": safe_text(artifact.get("quality", ""), 40) or "reference"
            });
        }
    }

    if len(links) == 0 {
        return {
            "status": "partial",
            "reason": "no_supporting_links",
            "summary": "No supporting links were available from observation or page artifacts.",
            "links": []
        };
    }

    return {
        "status": "success",
        "reason": "",
        "summary": "Collected bounded supporting links from explicit runtime artifacts.",
        "links": links
    };
}

"""R: Build bounded comparison notes from synthesis-eligible page artifacts before final synthesis.
M: Extracts short source-backed observations and records when comparison coverage is too narrow.
E: One or zero eligible pages returns a partial note set rather than invented contrasts.
"""
def compare_page_artifacts(page_artifacts: any) -> dict[str, any] {
    eligible_pages: list[any] = [];
    if isinstance(page_artifacts, list) {
        for artifact in page_artifacts {
            if isinstance(artifact, dict) and bool(artifact.get("synthesis_eligible", False)) {
                eligible_pages.append(artifact);
            }
        }
    }

    notes: list[str] = [];
    source_titles: list[str] = [];
    for artifact in eligible_pages {
        if len(notes) >= 3 {
            break;
        }
        add_unique_text(source_titles, artifact.get("title", ""), 140);
        sentence: str = concise_sentence(artifact.get("excerpt", ""), 160);
        if sentence {
            add_unique_text(notes, sentence, 160);
        }
    }

    if len(eligible_pages) < 2 {
        return {
            "status": "partial",
            "reason": "insufficient_comparison_inputs",
            "summary": "Comparison requested, but fewer than two synthesis-eligible artifacts were available.",
            "notes": notes,
            "source_titles": source_titles
        };
    }

    return {
        "status": "success",
        "reason": "",
        "summary": "Prepared bounded comparison notes from explicit eligible artifacts.",
        "notes": notes,
        "source_titles": source_titles
    };
}

"""R: Decide whether a set of page artifacts is strong enough for truthful synthesis.
M: Counts eligible and non-eligible classes, applies multi-source requirements, and returns a compact synthesis-input contract.
E: Zero eligible pages stays explicit so the runtime can refuse hub-only or weak-source synthesis.
"""
def build_synthesis_input(page_artifacts: any, require_multi_source: bool) -> dict[str, any] {
    eligible_pages: list[any] = [];
    blocked_classes: list[str] = [];
    if isinstance(page_artifacts, list) {
        for page in page_artifacts {
            if not isinstance(page, dict) {
                continue;
            }
            if bool(page.get("synthesis_eligible", False)) {
                eligible_pages.append(page);
            } else {
                add_unique_text(blocked_classes, page.get("classification", ""), 40);
            }
        }
    }

    eligibility: str = "eligible";
    reason: str = "";
    limitations: list[str] = [];

    if len(eligible_pages) == 0 {
        eligibility = "ineligible";
        reason = "no_synthesis_eligible_pages";
        limitations.append("No page artifact met synthesis eligibility requirements.");
        if "hub" in blocked_classes {
            limitations.append("Available pages were hub or index content.");
        }
    } elif require_multi_source and len(eligible_pages) < 2 {
        eligibility = "limited";
        reason = "insufficient_multi_source_coverage";
        limitations.append("Objective requested multi-source synthesis, but only one eligible page was available.");
    }

    return {
        "eligibility": eligibility,
        "reason": reason,
        "require_multi_source": require_multi_source,
        "eligible_pages": eligible_pages,
        "eligible_count": len(eligible_pages),
        "blocked_classes": blocked_classes,
        "limitations": limitations
    };
}

def concise_sentence(raw_text: any, max_len: int = 160) -> str {
    collapsed: str = " ".join(str(raw_text or "").split());
    if not collapsed {
        return "";
    }
    sentence_match: any = re.search(r"^(.+?[.!?])(?:\s|$)", collapsed);
    if sentence_match {
        return safe_text(sentence_match.group(1), max_len);
    }
    return safe_text(collapsed, max_len);
}

"""R: Build a bounded article summary from synthesis-eligible page artifacts only.
M: Pulls one sentence from each eligible page, preserves source-backed highlights, and adds limitations when coverage is narrow.
E: The function never falls back to non-eligible pages, so summary gaps remain explicit.
"""
def summarize_eligible_pages(synthesis_input: dict[str, any], prefer_fresh_sources: bool, max_chars: int = 280) -> dict[str, any] {
    eligible_pages: list[any] = synthesis_input.get("eligible_pages", []) if isinstance(synthesis_input.get("eligible_pages", []), list) else [];
    if len(eligible_pages) == 0 {
        return {
            "status": "blocked",
            "reason": safe_text(synthesis_input.get("reason", "no_synthesis_eligible_pages"), 80),
            "summary": "",
            "highlights": [],
            "limitations": synthesis_input.get("limitations", []),
            "sources": []
        };
    }

    sentences: list[str] = [];
    highlights: list[str] = [];
    sources: list[any] = [];
    for page in eligible_pages {
        if not isinstance(page, dict) {
            continue;
        }
        sentence: str = concise_sentence(page.get("excerpt", ""), 160);
        if sentence and sentence not in sentences {
            sentences.append(sentence);
        }
        add_unique_text(highlights, page.get("title", ""), 140);
        add_unique_text(highlights, sentence, 140);
        sources.append({
            "url": safe_text(page.get("url", ""), 500),
            "title": safe_text(page.get("title", ""), 180),
            "classification": safe_text(page.get("classification", ""), 40),
            "quality": safe_text(page.get("quality", ""), 40)
        });
        if len(sentences) >= 3 {
            break;
        }
    }

    summary_text: str = " ".join(sentences);
    summary_text = safe_text(summary_text, max_chars);
    status: str = "success";
    limitations: list[str] = normalize_text_list(synthesis_input.get("limitations", []), 6, 160);
    confidence: str = "high";

    if safe_text(synthesis_input.get("eligibility", ""), 40) == "limited" {
        status = "partial";
        confidence = "medium";
        limitations.append("Coverage is narrower than the objective requested.");
    } elif len(eligible_pages) == 1 {
        confidence = "medium";
    }
    if prefer_fresh_sources and len(eligible_pages) < 2 {
        add_unique_text(limitations, "News coverage is based on a narrow source set.", 160);
    }

    return {
        "status": status,
        "reason": "",
        "summary": summary_text,
        "highlights": highlights[:5],
        "limitations": limitations,
        "sources": sources,
        "confidence": confidence
    };
}

"""R: Build an honest limited-summary result when source quality is too weak for article-level synthesis.
M: Reports the data gap, counts usable artifacts, and avoids inventing narrative from hub or shell text.
E: This path intentionally stays terse so weak inputs do not produce junk summaries.
"""
def build_limited_summary(page_artifacts: any, reason: str) -> dict[str, any] {
    total_pages: int = 0;
    eligible_count: int = 0;
    hub_count: int = 0;
    if isinstance(page_artifacts, list) {
        for page in page_artifacts {
            if not isinstance(page, dict) {
                continue;
            }
            total_pages += 1;
            if bool(page.get("synthesis_eligible", False)) {
                eligible_count += 1;
            }
            if safe_text(page.get("classification", ""), 40) == "hub" {
                hub_count += 1;
            }
        }
    }

    summary: str = "Limited summary only. Source quality was too weak for article-level synthesis.";
    if reason == "hub_only_sources" {
        summary = "Refused synthesis because only hub or index pages were available.";
    }

    limitations: list[str] = [
        "Only synthesis-eligible article pages can drive the final summary.",
        "No fallback summary was generated from hub pages or shell text."
    ];
    if total_pages > 0 {
        limitations.append(
            "Received " + str(total_pages) + " page artifact" + ("s" if total_pages != 1 else "") +
            ", with " + str(eligible_count) + " eligible and " + str(hub_count) + " hub-like."
        );
    }

    return {
        "status": "partial",
        "reason": safe_text(reason, 80),
        "summary": summary,
        "highlights": [],
        "limitations": limitations,
        "sources": [],
        "confidence": "low"
    };
}

"""R: Detect whether the objective explicitly points at the active browser page.
M: Matches compact current-page phrases against the bounded objective text.
E: Ambiguous objectives return False so the planner prefers explicit source evidence.
"""
def objective_targets_current_page(objective: str) -> bool {
    objective_text: str = safe_text(objective, 240).lower();
    if not objective_text {
        return False;
    }
    if re.search(
        r"\b(do\s+not|don't|not)\s+(summari[sz]e|use|read|ground\s+on|focus\s+on)?\s*(the\s+)?(current page|this page)\b",
        objective_text
    ) {
        return False;
    }
    return re.search(r"\b(current page|this page|page i am on|what is happening on (the )?current page)\b", objective_text) is not None;
}

"""R: Detect whether the objective asks for broader cross-source coverage rather than one page read.
M: Looks for freshness and aggregation cues such as latest, recent, news, updates, and compare language.
E: Empty objectives return False so runtime inputs can drive the fallback intent.
"""
def objective_targets_external_sources(objective: str) -> bool {
    objective_text: str = safe_text(objective, 240).lower();
    if not objective_text {
        return False;
    }
    return re.search(r"\b(news|latest|recent|updates|headlines|sources|articles|compare|roundup)\b", objective_text) is not None;
}

"""R: Convert an external-source objective into a cleaner live-search query for v2.
M: Removes instruction boilerplate, browser-page caveats, and summary-format phrasing while preserving the actual topic and freshness cues.
E: If cleanup would over-strip the request, the normalized objective is returned so search still has a stable fallback.
"""
def derive_external_search_query(objective: str) -> str {
    normalized_objective: str = " ".join(str(objective or "").split());
    normalized_objective = safe_text(normalized_objective, 320);
    if not normalized_objective {
        return "";
    }

    query: str = normalized_objective;
    query = re.sub(r"(?i)^\s*(please\s+)?(search\s+the\s+web\s+(for\s+)?)", "", query);
    query = re.sub(r"(?i)^\s*(please\s+)?(summari[sz]e|brief|digest|research|investigate|look up|lookup|find|track|monitor|compare)\b\s*", "", query);
    query = re.sub(r"(?i)\b(gather|collect|use)\s+(multiple\s+)?(current|fresh|latest|recent|relevant)\s+sources\b", "", query);
    query = re.sub(r"(?i)\b(and\s+)?summari[sz]e\s+(them|it)\b", "", query);
    query = re.sub(r"(?i)\b(do\s+not|don't)\s+summari[sz]e\s+(the\s+)?(current|this)\s+page\b", "", query);
    query = re.sub(r"(?i)\bnot\s+(the\s+)?(current|this)\s+page\b", "", query);
    query = re.sub(r"(?i)\buse\s+normalized\s+browser\s+state\s+only\b", "", query);
    query = re.sub(r"(?i)\bdo\s+not\s+perform\b.*$", "", query);
    query = " ".join(query.replace(" ,", ",").split());
    query = query.strip(" ,;:-.");

    if len(query.split()) < 3 {
        return normalized_objective;
    }
    return safe_text(query, 320);
}

"""R: Detect whether the objective asks for explicit link extraction or research findings artifacts.
M: Matches bounded research phrases so the planner can request reusable supporting-link collection.
E: Generic summarization language alone does not trigger the extra extraction step.
"""
def objective_requests_supporting_links(objective: str) -> bool {
    objective_text: str = safe_text(objective, 240).lower();
    if not objective_text {
        return False;
    }
    return re.search(r"\b(research|useful links|extract links|findings|references|follow-up links)\b", objective_text) is not None;
}

"""R: Detect whether the objective explicitly asks for comparison across multiple artifacts.
M: Looks for compare/synthesize language that should produce an intermediate comparison step.
E: News-like aggregation cues alone do not force comparison unless the objective names it.
"""
def objective_requests_comparison(objective: str) -> bool {
    objective_text: str = safe_text(objective, 240).lower();
    if not objective_text {
        return False;
    }
    return re.search(r"\b(compare|contrast|differences|agreement|synthesize across)\b", objective_text) is not None;
}

"""R: Infer the user's high-level intent without introducing baked-in runtime product modes.
M: Combines the objective text with available injected inputs to choose a generic planning intent.
E: Mixed signals prefer explicit current-page language over weaker source hints.
"""
def infer_task_intent(payload: dict[str, any], objective: str) -> dict[str, any] {
    current_page_target: bool = objective_targets_current_page(objective);
    external_source_target: bool = objective_targets_external_sources(objective);
    has_opened_pages_input: bool = isinstance(payload.get("opened_pages", []), list) and len(payload.get("opened_pages", [])) > 0;
    has_search_results_input: bool = isinstance(payload.get("search_results", []), list) and len(payload.get("search_results", [])) > 0;
    has_trace_input: bool = isinstance(payload.get("trace_data", {}), dict) and len(payload.get("trace_data", {})) > 0;
    has_browser_hint: bool = isinstance(payload.get("browser_state_hint", {}), dict) and len(payload.get("browser_state_hint", {})) > 0;
    has_observation_hint: bool = safe_text(payload.get("browser_session_id", ""), 120) != "" or has_trace_input or has_browser_hint;

    intent: str = "current_page_grounding";
    evidence: list[str] = [];

    if current_page_target {
        intent = "current_page_grounding";
        evidence.append("objective_mentions_current_page");
    } elif external_source_target or has_opened_pages_input or has_search_results_input {
        intent = "cross_source_grounding";
        if external_source_target {
            evidence.append("objective_mentions_external_sources");
        }
        if has_opened_pages_input {
            evidence.append("payload_has_opened_pages");
        }
        if has_search_results_input {
            evidence.append("payload_has_search_results");
        }
    } elif has_observation_hint {
        intent = "current_page_grounding";
        evidence.append("payload_has_observation_input");
    }

    if len(evidence) == 0 {
        evidence.append("default_current_page_grounding");
    }

    return {
        "intent": intent,
        "evidence": evidence
    };
}

"""R: Infer what the runtime must obtain before it can produce an honest final artifact.
M: Converts task intent and objective cues into explicit requirement flags and synthesis expectations.
E: Caller-provided `require_multi_source` overrides the heuristic freshness default.
"""
def infer_task_requirements(payload: dict[str, any], objective: str, intent: dict[str, any]) -> dict[str, any] {
    current_page_grounding: bool = safe_text(intent.get("intent", ""), 60) == "current_page_grounding";
    require_multi_source: bool = objective_targets_external_sources(objective);
    if "require_multi_source" in payload and isinstance(payload.get("require_multi_source", False), bool) {
        require_multi_source = payload.get("require_multi_source", False);
    }

    return {
        "needs_current_observation": current_page_grounding,
        "needs_external_sources": not current_page_grounding,
        "needs_page_classification": True,
        "require_multi_source": require_multi_source,
        "require_article_grade_sources": not current_page_grounding,
        "prefer_fresh_sources": objective_targets_external_sources(objective),
        "needs_supporting_links": objective_requests_supporting_links(objective),
        "needs_comparison_notes": objective_requests_comparison(objective),
        "typed_artifacts_required": True
    };
}

"""R: Capture runtime limits and honesty constraints so the generated plan stays bounded and explicit.
M: Normalizes numeric controls and preserves read-only or IO-disable settings from the payload.
E: Unsupported values collapse to conservative defaults.
"""
def infer_task_constraints(payload: dict[str, any]) -> dict[str, any] {
    return {
        "max_sources": clamp_int_limit(payload.get("max_sources", 5), 5, 1, 8),
        "max_summary_chars": clamp_int_limit(payload.get("max_summary_chars", 280), 280, 120, 420),
        "io_mode": safe_text(payload.get("io_mode", ""), 24) or "default",
        "read_only": True,
        "honesty_required": True
    };
}

"""R: Infer which generic runtime capabilities are available before plan execution starts.
M: Inspects explicit payload inputs plus bounded IO policy to determine what the adapter can attempt.
E: Capabilities describe possible operations, not whether the later data will be strong enough.
"""
def infer_task_capabilities(payload: dict[str, any], requirements: dict[str, any], constraints: dict[str, any]) -> dict[str, any] {
    io_disabled: bool = safe_text(constraints.get("io_mode", ""), 24) == "disabled";
    has_opened_pages_input: bool = isinstance(payload.get("opened_pages", []), list) and len(payload.get("opened_pages", [])) > 0;
    has_search_results_input: bool = isinstance(payload.get("search_results", []), list) and len(payload.get("search_results", [])) > 0;
    has_browser_session: bool = safe_text(payload.get("browser_session_id", ""), 120) != "";
    has_trace_input: bool = isinstance(payload.get("trace_data", {}), dict) and len(payload.get("trace_data", {})) > 0;
    has_browser_hint: bool = isinstance(payload.get("browser_state_hint", {}), dict) and len(payload.get("browser_state_hint", {})) > 0;

    return {
        "has_opened_pages_input": has_opened_pages_input,
        "has_search_results_input": has_search_results_input,
        "has_observation_input": has_browser_session or has_trace_input or has_browser_hint,
        "can_load_observation": bool(requirements.get("needs_current_observation", False)),
        "can_load_sources": bool(requirements.get("needs_external_sources", False)) and (has_search_results_input or not io_disabled),
        "can_open_sources": bool(requirements.get("needs_external_sources", False)) and (has_opened_pages_input or not io_disabled),
        "can_classify_pages": True,
        "can_synthesize": True
    };
}

"""R: Generate one generic execution plan from inferred intent, requirements, and capabilities.
M: Chooses bounded reusable step types so task differences emerge from plan shape instead of mode branches.
E: Missing capabilities still yield a plan, allowing later execution to return an honest blocked result.
"""
def build_inferred_plan(requirements: dict[str, any], capabilities: dict[str, any]) -> list[any] {
    steps: list[any] = [];

    if bool(requirements.get("needs_current_observation", False)) {
        steps.append({"step_id": "load_observation", "type": "load_observation"});
        steps.append({"step_id": "summarize_current_page", "type": "summarize_current_page"});
        if bool(requirements.get("needs_supporting_links", False)) {
            steps.append({"step_id": "collect_supporting_links", "type": "collect_supporting_links"});
        }
    } else {
        if not bool(capabilities.get("has_opened_pages_input", False)) and (bool(capabilities.get("has_search_results_input", False)) or bool(capabilities.get("can_load_sources", False))) {
            steps.append({"step_id": "load_sources", "type": "load_sources"});
        }
        if not bool(capabilities.get("has_opened_pages_input", False)) and bool(capabilities.get("can_open_sources", False)) {
            steps.append({"step_id": "open_sources", "type": "open_sources"});
        }
        steps.append({"step_id": "classify_pages", "type": "classify_pages"});
        if bool(requirements.get("needs_comparison_notes", False)) {
            steps.append({"step_id": "compare_artifacts", "type": "compare_artifacts"});
        }
        if bool(requirements.get("needs_supporting_links", False)) {
            steps.append({"step_id": "collect_supporting_links", "type": "collect_supporting_links"});
        }
    }

    steps.append({"step_id": "synthesize", "type": "synthesize"});
    return steps;
}

"""R: Produce one reusable planning blueprint that keeps v2 plan-first and runtime-generated.
M: Infers intent, requirements, constraints, capabilities, and a generic plan from the payload.
E: The blueprint is descriptive only; execution still determines whether inputs are usable or blocked.
"""
def infer_execution_blueprint(payload: dict[str, any]) -> dict[str, any] {
    objective: str = safe_text(payload.get("objective", ""), 240) or "Summarize the current page honestly.";
    intent: dict[str, any] = infer_task_intent(payload, objective);
    requirements: dict[str, any] = infer_task_requirements(payload, objective, intent);
    constraints: dict[str, any] = infer_task_constraints(payload);
    capabilities: dict[str, any] = infer_task_capabilities(payload, requirements, constraints);
    plan: list[any] = build_inferred_plan(requirements, capabilities);

    return {
        "objective": objective,
        "intent": intent,
        "requirements": requirements,
        "constraints": constraints,
        "capabilities": capabilities,
        "plan": plan
    };
}

"""R: Execute one bounded runtime step against explicit artifacts and in-memory state.
M: Handles a small fixed step vocabulary and records consumed/produced artifact names plus provenance.
E: Unsupported capabilities stay blocked and visible instead of silently degrading into a fake success path.
"""
def execute_plan_step_v2(runtime_state: dict[str, any], plan_step: dict[str, any]) -> dict[str, any] {
    step_id: str = safe_text(plan_step.get("step_id", ""), 80) or "step";
    step_type: str = safe_text(plan_step.get("type", ""), 60);
    artifacts: dict[str, any] = runtime_state.get("artifacts", {}) if isinstance(runtime_state.get("artifacts", {}), dict) else {};
    objective: str = safe_text(runtime_state.get("objective", ""), 240);

    if step_type == "load_observation" {
        observation_input: dict[str, any] = load_observation_input(runtime_state.get("payload", {}));
        runtime_state["io"]["observation_input"] = sanitize_json_value(observation_input, 4, 12, 220);
        trace_data: dict[str, any] = observation_input.get("trace_data", {}) if isinstance(observation_input.get("trace_data", {}), dict) else {};
        browser_hint: dict[str, any] = observation_input.get("browser_hint", {}) if isinstance(observation_input.get("browser_hint", {}), dict) else {};
        observation: dict[str, any] = normalize_observation_snapshot(trace_data, browser_hint);
        runtime_state["artifacts"]["observation"] = observation;
        return {
            "step_id": step_id,
            "type": step_type,
            "status": safe_text(observation_input.get("status", ""), 24) or "partial",
            "reason": safe_text(observation_input.get("reason", ""), 80),
            "summary": safe_text(observation_input.get("summary", ""), 220) or "Loaded the normalized browser observation snapshot.",
            "provenance": sanitize_json_value(observation.get("provenance", []), 3, 6, 160),
            "consumes": [],
            "produces": ["observation"]
        };
    }

    if step_type == "load_sources" {
        source_payload: dict[str, any] = runtime_state.get("payload", {}) if isinstance(runtime_state.get("payload", {}), dict) else {};
        derived_query: str = derive_external_search_query(objective);
        if derived_query and not safe_text(source_payload.get("search_query", ""), 320) {
            source_payload["search_query"] = derived_query;
        }

        source_input: dict[str, any] = load_sources_input(source_payload);
        runtime_state["io"]["source_input"] = sanitize_json_value(source_input, 4, 12, 220);
        runtime_state["search_results"] = source_input.get("search_results", []);
        observation_links: any = [];
        if isinstance(artifacts.get("observation", {}), dict) {
            observation_links = artifacts.get("observation", {}).get("signals", {}).get("links", []);
        }
        result: dict[str, any] = score_source_candidates(runtime_state.get("search_results", []), observation_links, runtime_state.get("max_sources", 5));
        step_status: str = safe_text(result.get("status", ""), 24);
        step_reason: str = safe_text(result.get("reason", ""), 80);
        step_summary: str = safe_text(result.get("summary", ""), 220);
        if step_status == "blocked" and isinstance(runtime_state.get("opened_pages", []), list) and len(runtime_state.get("opened_pages", [])) > 0 {
            step_status = "partial";
            step_reason = "candidate_scoring_skipped";
            step_summary = "No source candidates were available, but the runtime continued with explicit opened pages.";
        }
        runtime_state["artifacts"]["source_candidates"] = result.get("candidates", []);
        return {
            "step_id": step_id,
            "type": step_type,
            "status": step_status,
            "reason": step_reason,
            "summary": safe_text(source_input.get("summary", ""), 220) or step_summary,
            "provenance": [{
                "kind": "source_inputs",
                "io_mode": safe_text(source_input.get("io_mode", ""), 24),
                "search_query": safe_text(source_payload.get("search_query", ""), 220),
                "result_count": len(runtime_state.get("search_results", [])),
                "ranked_count": len(result.get("candidates", []))
            }],
            "consumes": ["search_results"],
            "produces": ["source_candidates"]
        };
    }

    if step_type == "open_sources" {
        ranked_candidates: any = runtime_state.get("artifacts", {}).get("source_candidates", []);
        page_input: dict[str, any] = open_sources_input(runtime_state.get("payload", {}), ranked_candidates);
        runtime_state["io"]["page_input"] = sanitize_json_value(page_input, 4, 12, 2200);
        if page_input and isinstance(page_input.get("opened_pages", []), list) and len(page_input.get("opened_pages", [])) > 0 {
            runtime_state["opened_pages"] = page_input.get("opened_pages", []);
        }

        step_status = safe_text(page_input.get("status", ""), 24) or "blocked";
        if step_status == "blocked" and isinstance(runtime_state.get("opened_pages", []), list) and len(runtime_state.get("opened_pages", [])) > 0 {
            step_status = "partial";
        }
        return {
            "step_id": step_id,
            "type": step_type,
            "status": step_status,
            "reason": safe_text(page_input.get("reason", ""), 80),
            "summary": safe_text(page_input.get("summary", ""), 220),
            "provenance": [{
                "kind": "page_open_io",
                "io_mode": safe_text(page_input.get("io_mode", ""), 24),
                "candidate_count": len(ranked_candidates) if isinstance(ranked_candidates, list) else 0,
                "opened_count": len(runtime_state.get("opened_pages", []))
            }],
            "consumes": ["source_candidates"],
            "produces": ["opened_pages"]
        };
    }

    if step_type == "classify_pages" {
        result = classify_opened_pages(runtime_state.get("opened_pages", []));
        runtime_state["artifacts"]["page_artifacts"] = result.get("page_artifacts", []);
        return {
            "step_id": step_id,
            "type": step_type,
            "status": safe_text(result.get("status", ""), 24),
            "reason": safe_text(result.get("reason", ""), 80),
            "summary": safe_text(result.get("summary", ""), 220),
            "provenance": [{"kind": "opened_pages", "count": len(result.get("page_artifacts", []))}],
            "consumes": ["opened_pages"],
            "produces": ["page_artifacts"]
        };
    }

    if step_type == "compare_artifacts" {
        comparison_result: dict[str, any] = compare_page_artifacts(runtime_state.get("artifacts", {}).get("page_artifacts", []));
        runtime_state["artifacts"]["comparison_notes"] = comparison_result;
        return {
            "step_id": step_id,
            "type": step_type,
            "status": safe_text(comparison_result.get("status", ""), 24) or "partial",
            "reason": safe_text(comparison_result.get("reason", ""), 80),
            "summary": safe_text(comparison_result.get("summary", ""), 220),
            "provenance": [{"kind": "page_artifacts", "eligible_note_count": len(comparison_result.get("notes", []))}],
            "consumes": ["page_artifacts"],
            "produces": ["comparison_notes"]
        };
    }

    if step_type == "collect_supporting_links" {
        supporting_links: dict[str, any] = collect_supporting_links(
            artifacts.get("observation", {}),
            runtime_state.get("artifacts", {}).get("page_artifacts", []),
            5
        );
        runtime_state["artifacts"]["supporting_links"] = supporting_links;
        return {
            "step_id": step_id,
            "type": step_type,
            "status": safe_text(supporting_links.get("status", ""), 24) or "partial",
            "reason": safe_text(supporting_links.get("reason", ""), 80),
            "summary": safe_text(supporting_links.get("summary", ""), 220),
            "provenance": [{"kind": "supporting_links", "count": len(supporting_links.get("links", []))}],
            "consumes": ["observation", "page_artifacts"],
            "produces": ["supporting_links"]
        };
    }

    if step_type == "summarize_current_page" {
        observation = artifacts.get("observation", {}) if isinstance(artifacts.get("observation", {}), dict) else {};
        if not observation {
            return {
                "step_id": step_id,
                "type": step_type,
                "status": "blocked",
                "reason": "no_observation",
                "summary": "Current-page promotion requires a normalized observation snapshot.",
                "provenance": [],
                "consumes": ["observation"],
                "produces": []
            };
        }
        page_artifact: dict[str, any] = current_page_artifact_from_observation(observation);
        step_status: str = "success";
        step_reason: str = "";
        if safe_text(observation.get("source_kind", ""), 24) == "none" or safe_text(page_artifact.get("classification", ""), 40) == "low_content" {
            step_status = "partial";
            step_reason = "weak_current_page_observation";
        }
        runtime_state["artifacts"]["page_artifacts"] = [page_artifact];
        return {
            "step_id": step_id,
            "type": step_type,
            "status": step_status,
            "reason": step_reason,
            "summary": "Promoted the current observation into a classified page artifact.",
            "provenance": sanitize_json_value(page_artifact.get("provenance", []), 3, 4, 160),
            "consumes": ["observation"],
            "produces": ["page_artifacts"]
        };
    }

    if step_type == "synthesize" {
        page_artifacts: any = runtime_state.get("artifacts", {}).get("page_artifacts", []);
        synthesis_input: dict[str, any] = build_synthesis_input(page_artifacts, bool(runtime_state.get("require_multi_source", False)));
        runtime_state["artifacts"]["synthesis_input"] = synthesis_input;

        synthesis_result: dict[str, any] = {};
        if safe_text(synthesis_input.get("eligibility", ""), 40) == "ineligible" {
            reason: str = "weak_sources";
            blocked_classes: list[str] = synthesis_input.get("blocked_classes", []) if isinstance(synthesis_input.get("blocked_classes", []), list) else [];
            if len(blocked_classes) == 1 and blocked_classes[0] == "hub" {
                reason = "hub_only_sources";
            }
            synthesis_result = build_limited_summary(page_artifacts, reason);
        } else {
            synthesis_result = summarize_eligible_pages(
                synthesis_input,
                bool(runtime_state.get("prefer_fresh_sources", False)),
                runtime_state.get("max_summary_chars", 280)
            );
        }

        if isinstance(runtime_state.get("artifacts", {}).get("comparison_notes", {}), dict) {
            comparison_notes: dict[str, any] = runtime_state.get("artifacts", {}).get("comparison_notes", {});
            comparison_entries: list[any] = comparison_notes.get("notes", []) if isinstance(comparison_notes.get("notes", []), list) else [];
            for note in comparison_entries {
                add_unique_text(synthesis_result["highlights"], note, 140);
            }
            if safe_text(comparison_notes.get("status", ""), 24) == "partial" {
                add_unique_text(synthesis_result["limitations"], "Comparison coverage was limited by the available eligible artifacts.", 160);
            }
        }

        if isinstance(runtime_state.get("artifacts", {}).get("supporting_links", {}), dict) {
            supporting_links_result: dict[str, any] = runtime_state.get("artifacts", {}).get("supporting_links", {});
            supporting_links_list: list[any] = supporting_links_result.get("links", []) if isinstance(supporting_links_result.get("links", []), list) else [];
            if isinstance(synthesis_result.get("sources", []), list) {
                for link_entry in supporting_links_list {
                    if len(synthesis_result["sources"]) >= 5 or not isinstance(link_entry, dict) {
                        continue;
                    }
                    synthesis_result["sources"].append({
                        "url": safe_text(link_entry.get("url", ""), 500),
                        "title": safe_text(link_entry.get("title", ""), 180),
                        "classification": safe_text(link_entry.get("classification", ""), 40),
                        "quality": safe_text(link_entry.get("quality", ""), 40)
                    });
                }
            }
        }

        runtime_state["artifacts"]["final_output"] = synthesis_result;
        status: str = safe_text(synthesis_result.get("status", ""), 24) or "partial";
        return {
            "step_id": step_id,
            "type": step_type,
            "status": status,
            "reason": safe_text(synthesis_result.get("reason", ""), 80),
            "summary": "Prepared the final structured output from explicit synthesis inputs.",
            "provenance": [{"kind": "synthesis_input", "eligible_count": synthesis_input.get("eligible_count", 0)}],
            "consumes": ["page_artifacts"],
            "produces": ["synthesis_input", "final_output"]
        };
    }

    return {
        "step_id": step_id,
        "type": step_type,
        "status": "blocked",
        "reason": "unsupported_step_type",
        "summary": "This experimental runtime does not implement step type `" + step_type + "`.",
        "provenance": [],
        "consumes": [],
        "produces": []
    };
}

"""R: Run the experimental telemetry-first helper runtime without mutating the current helper path.
M: Normalizes observation state, executes a fixed bounded plan, and shapes one honest final output with provenance and limitations.
E: Missing capabilities or weak sources stay explicit in the returned plan/output rather than becoming hidden fallback behavior.
"""
def run_helper_v2(payload: dict[str, any]) -> dict[str, any] {
    blueprint: dict[str, any] = infer_execution_blueprint(payload);
    objective: str = safe_text(blueprint.get("objective", ""), 240);
    requirements: dict[str, any] = blueprint.get("requirements", {}) if isinstance(blueprint.get("requirements", {}), dict) else {};
    constraints: dict[str, any] = blueprint.get("constraints", {}) if isinstance(blueprint.get("constraints", {}), dict) else {};
    capabilities: dict[str, any] = blueprint.get("capabilities", {}) if isinstance(blueprint.get("capabilities", {}), dict) else {};
    plan: list[any] = blueprint.get("plan", []) if isinstance(blueprint.get("plan", []), list) else [];
    opened_pages: any = payload.get("opened_pages", []);

    runtime_state: dict[str, any] = {
        "payload": sanitize_json_value(payload, 5, 18, 260),
        "objective": objective,
        "max_sources": constraints.get("max_sources", 5) if isinstance(constraints.get("max_sources", 5), int) else 5,
        "max_summary_chars": constraints.get("max_summary_chars", 280) if isinstance(constraints.get("max_summary_chars", 280), int) else 280,
        "require_multi_source": bool(requirements.get("require_multi_source", False)),
        "prefer_fresh_sources": bool(requirements.get("prefer_fresh_sources", False)),
        "search_results": [],
        "opened_pages": sanitize_json_value(opened_pages, 4, 10, 900),
        "io": {
            "observation_input": {},
            "source_input": {},
            "page_input": {}
        },
        "artifacts": {}
    };
    step_results: list[any] = [];
    final_status: str = "success";
    blocked_reason: str = "";
    for plan_step in plan {
        step_result: dict[str, any] = execute_plan_step_v2(runtime_state, plan_step);
        step_results.append(step_result);
        step_status: str = safe_text(step_result.get("status", ""), 24);
        if step_status == "blocked" {
            final_status = "blocked";
            blocked_reason = safe_text(step_result.get("reason", ""), 80);
            break;
        }
        if step_status == "partial" and final_status == "success" {
            final_status = "partial";
        }
    }

    final_output: dict[str, any] = {};
    if isinstance(runtime_state.get("artifacts", {}).get("final_output", {}), dict) {
        final_output = runtime_state.get("artifacts", {}).get("final_output", {});
    }
    if not final_output {
        final_output = {
            "status": "blocked",
            "reason": blocked_reason or "no_final_output",
            "summary": "",
            "highlights": [],
            "limitations": ["The plan did not reach a final synthesis output."],
            "sources": [],
            "confidence": "low"
        };
    }

    return {
        "ok": True,
        "schema": OUTPUT_SCHEMA,
        "task_blueprint": sanitize_json_value(blueprint, 5, 16, 220),
        "observation": runtime_state.get("artifacts", {}).get("observation", {}),
        "source_candidates": runtime_state.get("artifacts", {}).get("source_candidates", []),
        "page_artifacts": runtime_state.get("artifacts", {}).get("page_artifacts", []),
        "synthesis_input": runtime_state.get("artifacts", {}).get("synthesis_input", {}),
        "final_output": {
            "schema": OUTPUT_SCHEMA,
            "objective": objective,
            "status": safe_text(final_output.get("status", final_status), 24),
            "reason": safe_text(final_output.get("reason", blocked_reason), 80),
            "summary": safe_text(final_output.get("summary", ""), runtime_state.get("max_summary_chars", 280)),
            "highlights": normalize_text_list(final_output.get("highlights", []), 5, 140),
            "sources": sanitize_json_value(final_output.get("sources", []), 4, 8, 180),
            "limitations": normalize_text_list(final_output.get("limitations", []), 8, 180),
            "confidence": safe_text(final_output.get("confidence", "low"), 24),
            "honest_notes": [
                "Final summaries only use synthesis-eligible page artifacts.",
                "Weak or hub-only inputs return limited output instead of improvised narrative."
            ]
        },
        "plan_execution": {
            "schema": PLAN_SCHEMA,
            "strategy": "telemetry_first_read_only_v2",
            "status": final_status if final_output else "blocked",
            "blocked_reason": blocked_reason,
            "generated_plan": sanitize_json_value(plan, 4, 12, 160),
            "step_results": sanitize_json_value(step_results, 5, 16, 220),
            "memory": {
                "objective": objective,
                "intent": sanitize_json_value(blueprint.get("intent", {}), 3, 8, 160),
                "requirements": sanitize_json_value(requirements, 3, 12, 160),
                "constraints": sanitize_json_value(constraints, 3, 12, 160),
                "capabilities": sanitize_json_value(capabilities, 3, 12, 160),
                "require_multi_source": bool(requirements.get("require_multi_source", False)),
                "io": sanitize_json_value(runtime_state.get("io", {}), 4, 12, 180)
            }
        }
    };
}

"""R: Parse one JSON payload for optional CLI use during local experimentation.
M: Joins argv entries after the command name and decodes a dict payload.
E: Invalid JSON returns an empty dict so the CLI path stays predictable.
"""
def parse_payload() -> dict[str, any] {
    raw_payload: str = "{}";
    if len(sys.argv) > 2 {
        raw_payload = " ".join(sys.argv[2:]);
    }

    try {
        parsed: any = json.loads(raw_payload);
        if isinstance(parsed, dict) {
            return parsed;
        }
    } except json.JSONDecodeError {
        return {};
    }
    return {};
}

def dispatch(command: str, payload: dict[str, any]) -> dict[str, any] {
    if command == "run_helper_v2" {
        return run_helper_v2(payload);
    }
    if command == "normalize_observation_snapshot" {
        return {
            "ok": True,
            "observation": normalize_observation_snapshot(payload.get("trace_data", {}), payload.get("browser_state_hint", {}))
        };
    }
    if command == "infer_execution_blueprint" {
        return {
            "ok": True,
            "task_blueprint": infer_execution_blueprint(payload)
        };
    }
    return {
        "ok": False,
        "error": "unknown command",
        "valid_commands": ["run_helper_v2", "normalize_observation_snapshot", "infer_execution_blueprint"]
    };
}

"""R: Decide whether the v2 helper module should run its optional CLI entrypoint.
M: Treats non-empty non-path-like argv values as commands and ignores import-time script paths.
E: Unknown commands still dispatch so direct CLI callers receive the normal usage payload.
"""
def should_dispatch_cli(command: str) -> bool {
    if not command {
        return False;
    }

    if command in PARENT_HELPERS_CLI_COMMANDS {
        return False;
    }

    return ("/" not in command) and ("\\" not in command) and not command.endswith(".jac");
}

with entry {
    command: str = "";
    if len(sys.argv) > 1 {
        command = str(sys.argv[1]);
    }

    if should_dispatch_cli(command) {
        print(json.dumps(dispatch(command, parse_payload()), indent=2));
    }
}
