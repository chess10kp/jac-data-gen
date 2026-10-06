"""
Isolated read-only IO adapter for the experimental helpers_v2 runtime.

Purpose:
- Keep network and trace binding separate from v2 reasoning contracts.
- Provide bounded search/open behavior for real inputs and fixture-backed tests.
- Return explicit partial or blocked states when IO is unavailable or weak.
"""

import os;
import json;
import re;
import from html { unescape }
import from urllib.parse { quote_plus, parse_qs, unquote, urlparse }
import from urllib.request { Request, urlopen }
import from urllib.error { HTTPError, URLError }
import from jac.layers.trace_utils { read_trace }

glob SEARCH_PROVIDER: str = "duckduckgo_html";
glob SEARCH_ENDPOINT: str = "https://html.duckduckgo.com/html/?q=";
glob USER_AGENT: str = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) " +
    "AppleWebKit/537.36 (KHTML, like Gecko) " +
    "Chrome/124.0.0.0 Safari/537.36"
);
glob OPEN_PAGE_MAX_BYTES: int = 120000;

"""R: Bound arbitrary values into compact plain-text fields for v2 IO results.
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

"""R: Keep IO payloads compact and transport-safe before handing them to the v2 runtime.
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

"""R: Normalize domains from URL-like values for search and page-open provenance.
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

"""R: Remove noisy HTML and convert it into bounded plain text for v2 IO outputs.
M: Strips comments, embeds, tags, and repeated whitespace while preserving readable content.
E: Empty or malformed HTML returns the empty string.
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
    cleaned = re.sub(r"</?(article|section|main|header|footer|aside|nav|div|p|br|li|ul|ol|h[1-6]|blockquote|tr|td)[^>]*>", "\n", cleaned, flags=re.IGNORECASE);
    cleaned = re.sub(r"<[^>]+>", " ", cleaned);
    cleaned = unescape(cleaned);
    cleaned = re.sub(r"\r", "\n", cleaned);
    cleaned = re.sub(r"\n+", "\n", cleaned);

    lines: list[str] = [];
    for raw_line in cleaned.split("\n") {
        line: str = " ".join(str(raw_line or "").split());
        if not line {
            continue;
        }
        if line not in lines {
            lines.append(safe_text(line, 280));
        }
    }

    return safe_text(" ".join(lines), max_len);
}

"""R: Bound search result counts for the v2 adapter.
M: Uses integer inputs when present and clamps them into a conservative range.
E: Invalid values collapse to the fallback.
"""
def normalize_limit(raw_limit: any, fallback: int = 5, max_value: int = 8) -> int {
    limit: int = fallback;
    if isinstance(raw_limit, int) and not isinstance(raw_limit, bool) {
        limit = raw_limit;
    }
    if limit < 1 {
        return 1;
    }
    if limit > max_value {
        return max_value;
    }
    return limit;
}

"""R: Extract target URLs from DuckDuckGo redirect links.
M: Handles absolute, protocol-relative, and site-relative hrefs plus `uddg` redirects.
E: Unexpected URLs fall back to bounded raw href text.
"""
def decode_search_result_href(raw_href: any) -> str {
    href: str = str(unescape(str(raw_href or ""))).strip();
    if not href {
        return "";
    }

    if href.startswith("//") {
        href = "https:" + href;
    } elif href.startswith("/") {
        href = "https://duckduckgo.com" + href;
    }

    try {
        parsed: any = urlparse(href);
        query_items: dict[str, any] = parse_qs(parsed.query);
        uddg_values: any = query_items.get("uddg", []);
        if isinstance(uddg_values, list) and len(uddg_values) > 0 {
            return safe_text(unquote(str(uddg_values[0])), 500);
        }
    } except ValueError {
        return safe_text(href, 500);
    }

    return safe_text(href, 500);
}

"""R: Parse structured source rows from one DuckDuckGo HTML response.
M: Finds result anchors, extracts nearby snippets, and returns bounded source dicts.
E: Unexpected markup yields fewer results instead of raising.
"""
def parse_duckduckgo_results(raw_html: str, max_results: int = 5) -> list[any] {
    results: list[any] = [];
    if not raw_html {
        return results;
    }

    anchor_pattern: any = re.compile(
        '<a[^>]*class="[^"]*result__a[^"]*"[^>]*href="([^"]+)"[^>]*>(.*?)</a>',
        re.IGNORECASE | re.DOTALL
    );
    anchors: any = list(anchor_pattern.finditer(raw_html));

    index: int = 0;
    while index < len(anchors) and len(results) < max_results {
        anchor_match: any = anchors[index];
        href: str = decode_search_result_href(anchor_match.group(1));
        title: str = clean_html_text(anchor_match.group(2), 180);
        if not href or not title {
            index += 1;
            continue;
        }

        next_start: int = int(anchor_match.end());
        next_end: int = len(raw_html);
        if index + 1 < len(anchors) {
            next_end = int(anchors[index + 1].start());
        }

        snippet_window: str = str(raw_html[next_start:next_end]);
        snippet_match: any = re.search(
            'class="[^"]*result__snippet[^"]*"[^>]*>(.*?)</',
            snippet_window,
            re.IGNORECASE | re.DOTALL
        );
        snippet: str = "";
        if snippet_match {
            snippet = clean_html_text(snippet_match.group(1), 240);
        }

        results.append({
            "href": href,
            "text": title,
            "domain": domain_from_url(href),
            "snippet": snippet,
            "rank": len(results) + 1,
            "provider": SEARCH_PROVIDER
        });
        index += 1;
    }

    return results;
}

"""R: Fetch search HTML from a bounded fixture or one live DuckDuckGo request.
M: Prefers v2-specific fixtures, falls back to legacy fixtures, then performs one GET request.
E: Network and HTTP failures return structured errors so v2 can stay honest.
"""
def fetch_search_html(query: str) -> dict[str, any] {
    fixture_html: str = str(os.environ.get("HELPER_V2_SEARCH_WEB_FIXTURE_HTML", "") or "");
    if not fixture_html {
        fixture_html = str(os.environ.get("HELPER_SEARCH_WEB_FIXTURE_HTML", "") or "");
    }
    if fixture_html {
        return {
            "ok": True,
            "provider": SEARCH_PROVIDER,
            "search_url": "fixture://helpers_v2_search",
            "raw_html": fixture_html,
            "from_fixture": True
        };
    }

    encoded_query: str = quote_plus(str(query or "").strip());
    if not encoded_query {
        return {"ok": False, "error": "missing_query"};
    }

    search_url: str = SEARCH_ENDPOINT + encoded_query;
    request: any = Request(
        search_url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept-Language": "en-US,en;q=0.9"
        },
        method="GET"
    );

    try {
        response: any = urlopen(request, timeout=12);
        raw_bytes: any = response.read();
        response.close();
        return {
            "ok": True,
            "provider": SEARCH_PROVIDER,
            "search_url": search_url,
            "raw_html": str(raw_bytes.decode("utf-8", errors="ignore")),
            "from_fixture": False
        };
    } except HTTPError as err {
        return {"ok": False, "error": "search_http_" + str(err.code), "search_url": search_url};
    } except URLError as err {
        return {"ok": False, "error": "search_network_error", "details": safe_text(err.reason or err, 180), "search_url": search_url};
    } except OSError as err {
        return {"ok": False, "error": "search_os_error", "details": safe_text(err, 180), "search_url": search_url};
    }
}

"""R: Build one normalized current-observation input for the v2 runtime.
M: Preferentially reads trace data, then falls back to explicit injected trace dicts and browser hints.
E: Missing trace data remains explicit so observation normalization can report a weak input honestly.
"""
def load_observation_input(payload: dict[str, any]) -> dict[str, any] {
    browser_session_id: str = safe_text(payload.get("browser_session_id", ""), 120);
    trace_data: dict[str, any] = {};
    source: str = "none";

    if browser_session_id {
        trace_data = read_trace(browser_session_id);
        if trace_data {
            source = "trace";
        } else {
            source = "trace_missing";
        }
    } elif isinstance(payload.get("trace_data", {}), dict) {
        trace_data = sanitize_json_value(payload.get("trace_data", {}), 5, 24, 220);
        if trace_data {
            source = "injected_trace";
        }
    }

    browser_hint: dict[str, any] = {};
    if isinstance(payload.get("browser_state_hint", {}), dict) {
        browser_hint = sanitize_json_value(payload.get("browser_state_hint", {}), 4, 16, 220);
    }

    status: str = "success";
    reason: str = "";
    summary: str = "Loaded current observation inputs for helpers_v2.";
    if not trace_data and len(browser_hint) == 0 {
        status = "partial";
        reason = "no_trace_or_hint";
        summary = "No trace or browser hint was available for the current observation input.";
    } elif not trace_data {
        status = "partial";
        reason = "hint_only";
        summary = "Only browser hint input was available for the current observation.";
    }

    return {
        "status": status,
        "reason": reason,
        "summary": summary,
        "trace_data": trace_data,
        "browser_hint": browser_hint,
        "provenance": [{"kind": source, "session_id": browser_session_id}]
    };
}

"""R: Produce bounded search inputs for v2 from explicit payload data or one live search request.
M: Reuses injected results when present, otherwise issues one search request unless IO is disabled.
E: Weak or unavailable IO returns partial or blocked output instead of fake results.
"""
def load_sources_input(payload: dict[str, any]) -> dict[str, any] {
    max_results: int = normalize_limit(payload.get("max_sources", 5), 5, 8);
    if isinstance(payload.get("search_results", []), list) and len(payload.get("search_results", [])) > 0 {
        return {
            "status": "success",
            "reason": "",
            "summary": "Using explicit search results supplied to helpers_v2.",
            "search_results": sanitize_json_value(payload.get("search_results", []), 4, 10, 220),
            "io_mode": "injected"
        };
    }

    if safe_text(payload.get("io_mode", ""), 24) == "disabled" {
        return {
            "status": "blocked",
            "reason": "search_io_disabled",
            "summary": "helpers_v2 search IO was disabled and no explicit search results were supplied.",
            "search_results": [],
            "io_mode": "disabled"
        };
    }

    query: str = safe_text(payload.get("search_query", ""), 320) or safe_text(payload.get("objective", ""), 320);
    fetch_result: dict[str, any] = fetch_search_html(query);
    if not bool(fetch_result.get("ok", False)) {
        return {
            "status": "blocked",
            "reason": safe_text(fetch_result.get("error", ""), 80) or "search_request_failed",
            "summary": "helpers_v2 could not fetch search results for the objective.",
            "search_results": [],
            "search_url": safe_text(fetch_result.get("search_url", ""), 400),
            "details": safe_text(fetch_result.get("details", ""), 180),
            "io_mode": "live"
        };
    }

    results: list[any] = parse_duckduckgo_results(str(fetch_result.get("raw_html", "")), max_results);
    status: str = "success";
    reason: str = "";
    summary: str = "helpers_v2 fetched bounded search results.";
    if len(results) == 0 {
        status = "partial";
        reason = "no_search_results";
        summary = "helpers_v2 completed search IO, but no bounded result rows were parsed.";
    }

    io_mode: str = "live";
    if bool(fetch_result.get("from_fixture", False)) {
        io_mode = "fixture";
    }

    return {
        "status": status,
        "reason": reason,
        "summary": summary,
        "search_results": results,
        "search_url": safe_text(fetch_result.get("search_url", ""), 400),
        "io_mode": io_mode
    };
}

"""R: Fetch one page through a bounded fixture or one live GET request for v2.
M: Prefers v2-specific fixtures, then legacy fixtures, then reads a capped response body and normalizes text.
E: Errors return structured failure payloads instead of raising.
"""
def fetch_open_page(url: str) -> dict[str, any] {
    normalized_url: str = safe_text(url, 500);
    if not normalized_url {
        return {
            "url": "",
            "status": "failed",
            "http_status": 0,
            "content_type": "",
            "title": "",
            "normalized_content": "",
            "content_excerpt": "",
            "error": "missing_url",
            "source": "none"
        };
    }

    fixture_json: str = str(os.environ.get("HELPER_V2_OPEN_PAGE_FIXTURE_JSON", "") or "");
    if not fixture_json {
        fixture_json = str(os.environ.get("HELPER_OPEN_PAGE_FIXTURE_JSON", "") or "");
    }
    if fixture_json {
        try {
            parsed_fixture: any = json.loads(fixture_json);
            if isinstance(parsed_fixture, dict) and isinstance(parsed_fixture.get(normalized_url, {}), dict) {
                fixture_entry: dict[str, any] = parsed_fixture.get(normalized_url, {});
                body: str = str(fixture_entry.get("body", "") or "");
                content_type: str = safe_text(fixture_entry.get("content_type", "text/html"), 120);
                title: str = safe_text(fixture_entry.get("title", ""), 180);
                normalized_content: str = clean_html_text(body, 2200);
                if not title {
                    title_match: any = re.search("<title[^>]*>(.*?)</title>", body, re.IGNORECASE | re.DOTALL);
                    if title_match {
                        title = clean_html_text(title_match.group(1), 180);
                    }
                }
                return {
                    "url": normalized_url,
                    "status": safe_text(fixture_entry.get("status", "success"), 24) or "success",
                    "http_status": fixture_entry.get("http_status", 200) if isinstance(fixture_entry.get("http_status", 200), int) else 200,
                    "content_type": content_type,
                    "title": title,
                    "normalized_content": normalized_content,
                    "content_excerpt": safe_text(normalized_content, 900),
                    "error": safe_text(fixture_entry.get("error", ""), 180),
                    "source": "fixture"
                };
            }
        } except json.JSONDecodeError {
            return {
                "url": normalized_url,
                "status": "failed",
                "http_status": 0,
                "content_type": "",
                "title": "",
                "normalized_content": "",
                "content_excerpt": "",
                "error": "invalid_open_page_fixture",
                "source": "fixture"
            };
        }
    }

    request: any = Request(
        normalized_url,
        headers={
            "User-Agent": USER_AGENT,
            "Accept-Language": "en-US,en;q=0.9"
        },
        method="GET"
    );

    try {
        response: any = urlopen(request, timeout=12);
        raw_bytes: any = response.read(OPEN_PAGE_MAX_BYTES);
        headers: any = response.info();
        status_code: int = int(response.getcode()) if response.getcode() else 200;
        response.close();

        content_type: str = safe_text(headers.get("Content-Type", ""), 120);
        decoded_body: str = str(raw_bytes.decode("utf-8", errors="ignore"));
        title: str = "";
        if "html" in content_type or "<html" in decoded_body.lower() {
            title_match: any = re.search("<title[^>]*>(.*?)</title>", decoded_body, re.IGNORECASE | re.DOTALL);
            if title_match {
                title = clean_html_text(title_match.group(1), 180);
            }
        }

        normalized_content: str = clean_html_text(decoded_body, 2200);
        page_status: str = "success";
        fetch_error: str = "";
        if not normalized_content and "text" not in content_type and "html" not in content_type and "json" not in content_type and "xml" not in content_type {
            page_status = "partial";
            fetch_error = "unsupported_content_type";
        }

        return {
            "url": normalized_url,
            "status": page_status,
            "http_status": status_code,
            "content_type": content_type,
            "title": title,
            "normalized_content": normalized_content,
            "content_excerpt": safe_text(normalized_content, 900),
            "error": fetch_error,
            "source": "network"
        };
    } except HTTPError as err {
        return {
            "url": normalized_url,
            "status": "failed",
            "http_status": err.code,
            "content_type": "",
            "title": "",
            "normalized_content": "",
            "content_excerpt": "",
            "error": "http_" + str(err.code),
            "source": "network"
        };
    } except URLError as err {
        return {
            "url": normalized_url,
            "status": "failed",
            "http_status": 0,
            "content_type": "",
            "title": "",
            "normalized_content": "",
            "content_excerpt": "",
            "error": "network_error: " + safe_text(err.reason or err, 180),
            "source": "network"
        };
    } except OSError as err {
        return {
            "url": normalized_url,
            "status": "failed",
            "http_status": 0,
            "content_type": "",
            "title": "",
            "normalized_content": "",
            "content_excerpt": "",
            "error": "os_error: " + safe_text(err, 180),
            "source": "network"
        };
    }
}

"""R: Open a bounded set of v2 source candidates into page inputs for page-artifact classification.
M: Prefers explicit opened pages, otherwise fetches top-ranked source URLs and preserves source provenance.
E: Complete fetch failure stays blocked instead of pretending pages were opened.
"""
def open_sources_input(payload: dict[str, any], ranked_candidates: any) -> dict[str, any] {
    if isinstance(payload.get("opened_pages", []), list) and len(payload.get("opened_pages", [])) > 0 {
        return {
            "status": "success",
            "reason": "",
            "summary": "Using explicit opened pages supplied to helpers_v2.",
            "opened_pages": sanitize_json_value(payload.get("opened_pages", []), 4, 10, 900),
            "io_mode": "injected"
        };
    }

    if safe_text(payload.get("io_mode", ""), 24) == "disabled" {
        return {
            "status": "blocked",
            "reason": "page_open_io_disabled",
            "summary": "helpers_v2 page-open IO was disabled and no explicit pages were supplied.",
            "opened_pages": [],
            "io_mode": "disabled"
        };
    }

    requested_pages: list[any] = [];
    if isinstance(ranked_candidates, list) {
        requested_pages = ranked_candidates;
    }
    if len(requested_pages) == 0 {
        return {
            "status": "blocked",
            "reason": "missing_ranked_candidates",
            "summary": "helpers_v2 page-open IO requires ranked source candidates or explicit opened pages.",
            "opened_pages": [],
            "io_mode": "live"
        };
    }

    max_pages: int = normalize_limit(payload.get("max_sources", 5), 5, 5);
    opened_pages: list[any] = [];
    success_count: int = 0;
    issue_count: int = 0;

    for candidate in requested_pages {
        if len(opened_pages) >= max_pages or not isinstance(candidate, dict) {
            continue;
        }

        url_value: str = safe_text(candidate.get("url", ""), 500) or safe_text(candidate.get("href", ""), 500);
        if not url_value {
            continue;
        }

        page_result: dict[str, any] = fetch_open_page(url_value);
        opened_page: dict[str, any] = {
            "url": safe_text(page_result.get("url", ""), 500),
            "title": safe_text(page_result.get("title", ""), 180) or safe_text(candidate.get("title", ""), 180) or safe_text(candidate.get("text", ""), 180),
            "status": safe_text(page_result.get("status", ""), 24),
            "http_status": page_result.get("http_status", 0) if isinstance(page_result.get("http_status", 0), int) else 0,
            "content_type": safe_text(page_result.get("content_type", ""), 120),
            "normalized_content": safe_text(page_result.get("normalized_content", ""), 2200),
            "content_excerpt": safe_text(page_result.get("content_excerpt", ""), 900),
            "fetch_error": safe_text(page_result.get("error", ""), 180),
            "domain": safe_text(candidate.get("domain", ""), 180) or domain_from_url(page_result.get("url", "")),
            "source_rank": candidate.get("rank", 0) if isinstance(candidate.get("rank", 0), int) else 0,
            "source_snippet": safe_text(candidate.get("snippet", ""), 240),
            "source_origin": safe_text(candidate.get("origin", ""), 40),
            "source_mode": safe_text(page_result.get("source", ""), 24)
        };
        opened_pages.append(opened_page);

        if safe_text(page_result.get("status", ""), 24) == "success" {
            success_count += 1;
        } else {
            issue_count += 1;
        }
    }

    if success_count == 0 {
        return {
            "status": "blocked",
            "reason": "page_fetch_failed",
            "summary": "helpers_v2 could not fetch any ranked source pages successfully.",
            "opened_pages": opened_pages,
            "io_mode": "live"
        };
    }

    status: str = "success";
    summary: str = "helpers_v2 opened bounded ranked source pages.";
    if issue_count > 0 {
        status = "partial";
        summary = "helpers_v2 opened some ranked source pages, with explicit fetch gaps.";
    }

    first_source_mode: str = "";
    if len(opened_pages) > 0 and isinstance(opened_pages[0], dict) {
        first_source_mode = safe_text(opened_pages[0].get("source_mode", ""), 24);
    }

    return {
        "status": status,
        "reason": "",
        "summary": summary,
        "opened_pages": opened_pages,
        "io_mode": first_source_mode or "live"
    };
}

"""R: Preserve the earlier v2 adapter surface while the runtime moves to generic plan terminology.
M: Delegates directly to the generic observation loader.
E: Output shape stays identical so comparison and external experiments do not break.
"""
def load_current_observation_input(payload: dict[str, any]) -> dict[str, any] {
    return load_observation_input(payload);
}

"""R: Preserve the earlier v2 adapter surface while the runtime moves to generic plan terminology.
M: Delegates directly to the generic source loader.
E: Output shape stays identical so comparison and external experiments do not break.
"""
def load_source_search_input(payload: dict[str, any]) -> dict[str, any] {
    return load_sources_input(payload);
}

"""R: Preserve the earlier v2 adapter surface while the runtime moves to generic plan terminology.
M: Delegates directly to the generic source opener.
E: Output shape stays identical so comparison and external experiments do not break.
"""
def load_page_open_input(payload: dict[str, any], ranked_candidates: any) -> dict[str, any] {
    return open_sources_input(payload, ranked_candidates);
}
