"""
Small comparison runner for the current helper runtime and helpers_v2.

Run with:
`jac run jac/helpers_compare_v2.jac`
"""

import sys;
import json;
import time;
import os;
import from jac.layers.helpers {
    create_helper,
    run_helper_once
}
import from jac.layers.helpers_v2 { run_helper_v2 }
import from jac.layers.observation { write_trace }

glob SEARCH_FIXTURE_HTML: str = (
    "<html><body>" +
    "<div class=\"result results_links\">" +
    "<a class=\"result__a\" href=\"https://example.com/ai-news/\">AI News: Latest Machine Learning &amp; Robotics Updates</a>" +
    "<a class=\"result__snippet\">Stay updated with the latest AI news and updates from around the industry.</a>" +
    "</div>" +
    "<div class=\"result results_links\">" +
    "<a class=\"result__a\" href=\"https://www.reuters.com/technology/openai-ships-lower-latency-enterprise-tools-2026-04-05/\">OpenAI ships lower-latency enterprise tools</a>" +
    "<a class=\"result__snippet\">Reuters reports OpenAI released new deployment controls and lower-latency multimodal tooling for enterprises.</a>" +
    "</div>" +
    "<div class=\"result results_links\">" +
    "<a class=\"result__a\" href=\"https://www.pcmag.com/news/meta-launches-new-agent-tooling-for-developers\">Meta launches new agent tooling for developers</a>" +
    "<a class=\"result__snippet\">PCMag says the release adds debugging controls, rollout guardrails, and workflow automation features.</a>" +
    "</div>" +
    "</body></html>"
);
glob OPEN_PAGE_FIXTURE: dict[str, any] = {
    "https://example.com/ai-news/": {
        "http_status": 200,
        "content_type": "text/html; charset=utf-8",
        "body": "<html><head><title>AI News: Latest Machine Learning &amp; Robotics Updates</title></head><body><main><h1>AI News: Latest Machine Learning &amp; Robotics Updates</h1><p>Stay updated with the latest AI news and updates from around the industry.</p></main></body></html>"
    },
    "https://www.reuters.com/technology/openai-ships-lower-latency-enterprise-tools-2026-04-05/": {
        "http_status": 200,
        "content_type": "text/html; charset=utf-8",
        "body": "<html><head><title>OpenAI ships lower-latency enterprise tools</title></head><body><article><p>OpenAI introduced lower-latency multimodal models and new enterprise deployment controls for production teams.</p><p>Executives said the update improves tool use and rollout governance for customer-facing workflows.</p></article></body></html>"
    },
    "https://www.pcmag.com/news/meta-launches-new-agent-tooling-for-developers": {
        "http_status": 200,
        "content_type": "text/html; charset=utf-8",
        "body": "<html><head><title>Meta launches new agent tooling for developers</title></head><body><article><p>Meta launched new debugging controls, rollout guardrails, and agent workflow automation features for developers.</p><p>The release focuses on safer deployments and better observability for production assistants.</p></article></body></html>"
    }
};
glob ARTICLE_PAGES: list[any] = [
    {
        "url": "https://www.reuters.com/technology/openai-ships-lower-latency-enterprise-tools-2026-04-05/",
        "title": "OpenAI ships lower-latency enterprise tools",
        "http_status": 200,
        "content_type": "text/html",
        "content_excerpt": "OpenAI introduced lower-latency multimodal models and new enterprise deployment controls for production teams. Executives said the update improves tool use and rollout governance for customer-facing workflows."
    },
    {
        "url": "https://www.pcmag.com/news/meta-launches-new-agent-tooling-for-developers",
        "title": "Meta launches new agent tooling for developers",
        "http_status": 200,
        "content_type": "text/html",
        "content_excerpt": "Meta launched new debugging controls, rollout guardrails, and agent workflow automation features for developers. The release focuses on safer deployments and better observability for production assistants."
    },
    {
        "url": "https://example.com/story/cloud-inference-expansion-helps-ai-rollouts",
        "title": "Cloud inference expansion helps AI rollouts",
        "http_status": 200,
        "content_type": "text/html",
        "content_excerpt": "Cloud vendors expanded inference clusters and managed serving options for evaluation and deployment workloads. Teams highlighted lower queuing delays and better capacity planning for enterprise launches."
    }
];

"""R: Parse one optional JSON payload from argv for local runtime comparison.
M: Joins argv fragments after the command name and decodes only dict payloads.
E: Invalid JSON returns an empty dict so the runner stays predictable.
"""
def parse_payload() -> dict[str, any] {
    raw_payload: str = "{}";
    env_payload: str = str(os.environ.get("HELPERS_COMPARE_V2_PAYLOAD_JSON", "") or "");
    if env_payload {
        raw_payload = env_payload;
    } elif len(sys.argv) > 1 {
        raw_payload = " ".join(sys.argv[1:]);
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

"""R: Provide one compact trace fixture for current-page comparison runs.
M: Writes a telemetry-rich trace only when the payload does not already specify one.
E: News-only runs can skip trace creation entirely.
"""
def ensure_trace(payload: dict[str, any]) -> str {
    if safe_text(payload.get("browser_session_id", ""), 120) {
        return safe_text(payload.get("browser_session_id", ""), 120);
    }

    session_id: str = "compare_v2_" + str(time.time()).replace(".", "");
    write_trace(session_id, {
        "session_id": session_id,
        "source_url": "https://example.com/research",
        "updated_at": "2026-04-05T00:01:00Z",
        "telemetry_counts": {"navigate": 1, "page_ready": 1, "page_semantic": 1},
        "latest_semantic": {
            "title": "Example Research Page",
            "page_kind": "content",
            "workflow_stage": "consume",
            "headings": ["Quarterly report", "Key metrics"],
            "primary_actions": ["Download report", "Open details"]
        },
        "latest_dom_snapshot": {
            "title": "Example Research Page",
            "body_text_sample": "Revenue increased by 18 percent year over year across the core product line. Management highlighted enterprise demand and rollout execution.",
            "headings": ["Quarterly report", "Key metrics"],
            "links": [{"text": "Metrics breakdown", "href": "https://example.com/story/metrics-breakdown-2026-04-05", "path": "body > main > a.metrics"}]
        },
        "latest_session_state": {"origin": "https://example.com", "pathname": "/research"},
        "events": [{"type": "navigate", "url": "https://example.com/research", "recorded_at": "2026-04-05T00:00:20Z"}]
    });
    return session_id;
}

def safe_text(value: any, max_len: int = 240) -> str {
    text: str = str(value or "").strip();
    if len(text) > max_len {
        return text[:max_len];
    }
    return text;
}

"""R: Build a compact scenario suite that probes multiple generic task shapes through the comparison path.
M: Reuses the same fixtures while varying only the objective and explicit injected artifacts.
E: Each scenario stays bounded so the runner remains deterministic in local evaluation.
"""
def default_scenarios() -> list[any] {
    return [
        {"name": "latest_news", "objective": "Summarize the latest AI news and updates"},
        {"name": "current_page_summary", "objective": "Summarize the current page"},
        {"name": "current_page_research", "objective": "Research the current page and extract useful links and findings"},
        {"name": "compare_sources", "objective": "Compare a few sources and synthesize the differences", "opened_pages": ARTICLE_PAGES},
        {"name": "opened_pages_summary", "objective": "Summarize a set of already opened pages", "opened_pages": ARTICLE_PAGES}
    ];
}

"""R: Create one temporary helper definition for comparing the current runtime with helpers_v2.
M: Uses the same user objective so both runtimes receive equivalent task framing.
E: Helper creation failures bubble up through the returned comparison output.
"""
def run_current_runtime(payload: dict[str, any]) -> dict[str, any] {
    create_result: dict[str, any] = create_helper({
        "name": "helpers_v2_compare_" + str(time.time()).replace(".", ""),
        "goal": safe_text(payload.get("objective", ""), 240) or "Summarize the current page honestly.",
        "frequency": "once"
    });
    if not bool(create_result.get("ok", False)) {
        return {"ok": False, "error": "helper_create_failed"};
    }

    helper_bundle: dict[str, any] = create_result.get("helper_bundle", {});
    helper_id: str = str(helper_bundle.get("helper", {}).get("helper_id", ""));
    run_payload: dict[str, any] = {
        "helper_id": helper_id,
        "browser_session_id": safe_text(payload.get("browser_session_id", ""), 120),
        "browser_state_hint": payload.get("browser_state_hint", {})
    };

    current_result: dict[str, any] = run_helper_once(run_payload);
    if not bool(current_result.get("ok", False)) {
        return current_result;
    }

    run_record: dict[str, any] = current_result.get("run", {});
    structured_output: dict[str, any] = run_record.get("structured_output", {}) if isinstance(run_record.get("structured_output", {}), dict) else {};
    return {
        "ok": True,
        "status": safe_text(run_record.get("status", ""), 24),
        "summary": safe_text(structured_output.get("summary", ""), 320) or safe_text(run_record.get("summary", ""), 320),
        "sources": structured_output.get("sources", []),
        "plan_execution": structured_output.get("plan_execution", {})
    };
}

"""R: Execute one bounded comparison case for the current runtime and v2 using the same objective framing.
M: Ensures current-page scenarios get trace context, runs both runtimes, and extracts the compact fields needed for evaluation.
E: The current runtime may ignore v2-only injected artifacts, so the output keeps both results visible instead of forcing parity.
"""
def run_comparison_case(base_payload: dict[str, any]) -> dict[str, any] {
    payload: dict[str, any] = dict(base_payload);
    objective: str = safe_text(payload.get("objective", ""), 240);
    wants_current_page: bool = objective == "" or ("current page" in objective.lower()) or ("this page" in objective.lower());
    if wants_current_page and not safe_text(payload.get("browser_session_id", ""), 120) {
        payload["browser_session_id"] = ensure_trace(payload);
    }

    current_result: dict[str, any] = run_current_runtime(payload);
    v2_result: dict[str, any] = run_helper_v2(payload);
    return {
        "name": safe_text(payload.get("name", ""), 80),
        "objective": objective,
        "current_runtime": current_result,
        "helpers_v2": {
            "intent": v2_result.get("task_blueprint", {}).get("intent", {}),
            "requirements": v2_result.get("task_blueprint", {}).get("requirements", {}),
            "status": safe_text(v2_result.get("final_output", {}).get("status", ""), 24),
            "summary": safe_text(v2_result.get("final_output", {}).get("summary", ""), 320),
            "sources": v2_result.get("final_output", {}).get("sources", []),
            "plan_execution": v2_result.get("plan_execution", {})
        }
    };
}

with entry {
    payload: dict[str, any] = parse_payload();
    use_fixture_io: bool = True;
    if isinstance(payload.get("use_fixture_io", True), bool) {
        use_fixture_io = payload.get("use_fixture_io", True);
    }
    if use_fixture_io {
        os.environ["HELPER_SEARCH_WEB_FIXTURE_HTML"] = SEARCH_FIXTURE_HTML;
        os.environ["HELPER_OPEN_PAGE_FIXTURE_JSON"] = json.dumps(OPEN_PAGE_FIXTURE);
    }

    if safe_text(payload.get("objective", ""), 240) {
        print(json.dumps(run_comparison_case(payload), indent=2));
    } else {
        scenarios: list[any] = [];
        for scenario in default_scenarios() {
            scenarios.append(run_comparison_case(scenario));
        }
        print(json.dumps({"scenarios": scenarios}, indent=2));
    }
}
