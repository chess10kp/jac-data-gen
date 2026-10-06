"""
Experimental telemetry-first helper runtime tests.

Run with: jac run jac/helpers_v2_test.jac
"""

import time;
import os;
import json;
import from jac.layers.helpers_v2 {
    infer_execution_blueprint,
    normalize_observation_snapshot,
    score_source_candidates,
    normalize_page_artifact,
    classify_page_artifact,
    derive_external_search_query,
    run_helper_v2
}
import from jac.layers.helpers {
    create_helper,
    run_helper_once
}
import from jac.layers.observation { write_trace }

glob COUNTS: dict[str, int] = {"passed": 0, "failed": 0};

glob SEARCH_RESULTS: list[any] = [
    {
        "href": "https://example.com/ai-news/",
        "text": "AI News: Latest Machine Learning & Robotics Updates",
        "snippet": "Stay updated with the latest AI news and updates from around the industry."
    },
    {
        "href": "https://www.reuters.com/technology/openai-ships-lower-latency-enterprise-tools-2026-04-05/",
        "text": "OpenAI ships lower-latency enterprise tools",
        "snippet": "Reuters reports OpenAI released lower-latency multimodal models and enterprise deployment controls."
    },
    {
        "href": "https://www.pcmag.com/news/meta-launches-new-agent-tooling-for-developers",
        "text": "Meta launches new agent tooling for developers",
        "snippet": "PCMag says the release adds debugging controls, rollout guardrails, and workflow automation features."
    },
    {
        "href": "https://news.google.com/topics/CAAqJggKIiBDQkFTRWdvSkwyMHZNRFZxYUdjU0FtVnVLQUFQAQ",
        "text": "Google News - Artificial intelligence - Latest",
        "snippet": "Get the latest Artificial intelligence news and updates."
    }
];

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

glob HUB_PAGES: list[any] = [
    {
        "url": "https://example.com/ai-news/",
        "title": "AI News: Latest Machine Learning & Robotics Updates",
        "http_status": 200,
        "content_type": "text/html",
        "content_excerpt": "Stay updated with the latest AI news and updates from around the industry."
    },
    {
        "url": "https://news.google.com/topics/CAAqJggKIiBDQkFTRWdvSkwyMHZNRFZxYUdjU0FtVnVLQUFQAQ",
        "title": "Google News - Artificial intelligence - Latest",
        "http_status": 200,
        "content_type": "text/html",
        "content_excerpt": "Get the latest Artificial intelligence news and updates."
    }
];

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

glob WEAK_PAGES: list[any] = [
    {
        "url": "https://vendor.example.com/platform",
        "title": "Transform your business with Agent Platform",
        "http_status": 200,
        "content_type": "text/html",
        "content_excerpt": "Book a demo and get started today with a platform trusted by leading teams."
    },
    {
        "url": "https://vendor.example.com/launch",
        "title": "Launch page",
        "http_status": 200,
        "content_type": "text/html",
        "content_excerpt": "Learn more."
    }
];

def assert_eq(label: str, got: any, expected: any) {
    if got == expected {
        COUNTS["passed"] = COUNTS["passed"] + 1;
        print("PASS  " + label);
    } else {
        COUNTS["failed"] = COUNTS["failed"] + 1;
        print("FAIL  " + label);
        print("      got:      " + str(got));
        print("      expected: " + str(expected));
    }
}

def assert_true(label: str, condition: bool) {
    assert_eq(label, condition, True);
}

def set_v2_fixture_io(enabled: bool) {
    if enabled {
        os.environ["HELPER_V2_SEARCH_WEB_FIXTURE_HTML"] = SEARCH_FIXTURE_HTML;
        os.environ["HELPER_V2_OPEN_PAGE_FIXTURE_JSON"] = json.dumps(OPEN_PAGE_FIXTURE);
    } else {
        os.environ["HELPER_V2_SEARCH_WEB_FIXTURE_HTML"] = "";
        os.environ["HELPER_V2_OPEN_PAGE_FIXTURE_JSON"] = "";
    }
}

"""R: Build one telemetry-rich observation fixture for the experimental runtime.
M: Reuses the same trace seams as the existing helper path so v2 proves it can bind to real repo telemetry.
E: The fixture stays compact while still covering headings, text, links, actions, and navigation events.
"""
def mk_trace(session_id: str) -> dict[str, any] {
    return {
        "session_id": session_id,
        "source_url": "https://example.com/research",
        "updated_at": "2026-04-05T00:01:00Z",
        "telemetry_counts": {
            "navigate": 1,
            "page_ready": 1,
            "page_semantic": 1
        },
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
            "buttons": [
                {"text": "Download report", "label": "Download report", "path": "body > main > button.download"}
            ],
            "links": [
                {"text": "Investor relations", "href": "https://example.com/investors", "path": "body > main > a.investors"},
                {"text": "Metrics breakdown", "href": "https://example.com/story/metrics-breakdown-2026-04-05", "path": "body > main > a.metrics"}
            ],
            "forms": [
                {
                    "method": "GET",
                    "action": "/search",
                    "field_count": 1,
                    "submit_text": "Search",
                    "labels": ["Search reports"],
                    "path": "body > main > form"
                }
            ]
        },
        "latest_session_state": {
            "origin": "https://example.com",
            "pathname": "/research"
        },
        "events": [
            {"type": "navigate", "url": "https://example.com/research", "recorded_at": "2026-04-05T00:00:20Z"},
            {"type": "page_ready", "url": "https://example.com/research", "recorded_at": "2026-04-05T00:00:50Z"}
        ]
    };
}

def test_normalized_telemetry_state_shape() {
    observation: dict[str, any] = normalize_observation_snapshot(mk_trace("sess_v2_shape"), {});

    assert_eq("v2 observation schema", str(observation.get("schema", "")), "helpers_v2/observation_snapshot");
    assert_eq("v2 observation source kind", str(observation.get("source_kind", "")), "trace");
    assert_eq("v2 observation page domain", str(observation.get("page", {}).get("domain", "")), "example.com");
    assert_true("v2 observation has text blocks", len(observation.get("signals", {}).get("text_blocks", [])) >= 1);
    assert_true("v2 observation has links", len(observation.get("signals", {}).get("links", [])) >= 2);
    assert_true("v2 observation has actions", len(observation.get("signals", {}).get("actions", [])) >= 2);
}

def test_source_candidate_scoring() {
    ranked: dict[str, any] = score_source_candidates(SEARCH_RESULTS, [], 3);
    candidates: list[any] = ranked.get("candidates", []) if isinstance(ranked.get("candidates", []), list) else [];

    assert_eq("v2 source scoring success", str(ranked.get("status", "")), "success");
    assert_true("v2 source scoring returns 3", len(candidates) == 3);
    assert_eq("v2 source scoring promotes Reuters first", str(candidates[0].get("domain", "")), "reuters.com");
    assert_eq("v2 source scoring keeps hub out of first slot", bool(candidates[0].get("page_shape", "") == "hub_like"), False);
}

def test_page_classification() {
    article_page: dict[str, any] = classify_page_artifact(normalize_page_artifact(ARTICLE_PAGES[0], "opened_page", 0));
    section_article_page: dict[str, any] = classify_page_artifact(normalize_page_artifact(ARTICLE_PAGES[1], "opened_page", 1));
    hub_page: dict[str, any] = classify_page_artifact(normalize_page_artifact(HUB_PAGES[0], "opened_page", 1));
    weak_page: dict[str, any] = classify_page_artifact(normalize_page_artifact(WEAK_PAGES[0], "opened_page", 2));
    error_page: dict[str, any] = classify_page_artifact(normalize_page_artifact({
        "url": "https://example.com/error",
        "title": "Server Error",
        "http_status": 500,
        "content_excerpt": ""
    }, "opened_page", 3));

    assert_eq("v2 article classified article", str(article_page.get("classification", "")), "article");
    assert_eq("v2 section article stays article", str(section_article_page.get("classification", "")), "article");
    assert_eq("v2 hub classified hub", str(hub_page.get("classification", "")), "hub");
    assert_eq("v2 marketing classified marketing", str(weak_page.get("classification", "")), "marketing_page");
    assert_eq("v2 error classified error", str(error_page.get("classification", "")), "error_page");
}

def test_summarize_from_article_path() {
    result: dict[str, any] = run_helper_v2({
        "objective": "Summarize recent AI news and updates",
        "trace_data": mk_trace("sess_v2_article"),
        "search_results": SEARCH_RESULTS,
        "opened_pages": ARTICLE_PAGES
    });

    final_output: dict[str, any] = result.get("final_output", {}) if isinstance(result.get("final_output", {}), dict) else {};
    summary: str = str(final_output.get("summary", ""));

    assert_eq("v2 article path success", str(final_output.get("status", "")), "success");
    assert_true("v2 article path summary uses article content", "deployment controls" in summary or "rollout guardrails" in summary or "inference clusters" in summary);
    assert_eq("v2 article path avoids hub fallback phrase", "latest AI news and updates" in summary, False);
    assert_true("v2 article path has sources", len(final_output.get("sources", [])) >= 2);
}

def test_v2_real_io_fixture_path_for_news() {
    set_v2_fixture_io(True);
    result: dict[str, any] = run_helper_v2({
        "objective": "Summarize the latest AI news and updates"
    });
    set_v2_fixture_io(False);

    final_output: dict[str, any] = result.get("final_output", {}) if isinstance(result.get("final_output", {}), dict) else {};
    plan_execution: dict[str, any] = result.get("plan_execution", {}) if isinstance(result.get("plan_execution", {}), dict) else {};
    steps: list[any] = plan_execution.get("step_results", []) if isinstance(plan_execution.get("step_results", []), list) else [];

    assert_eq("v2 real io fixture path success", str(final_output.get("status", "")), "success");
    assert_true("v2 real io fixture summary grounded", "deployment controls" in str(final_output.get("summary", "")) or "rollout guardrails" in str(final_output.get("summary", "")));
    assert_true("v2 real io fixture has generic steps", len(steps) == 4);
    assert_eq("v2 real io fixture first step type", str(steps[0].get("type", "")), "load_sources");
    assert_eq("v2 real io fixture second step type", str(steps[1].get("type", "")), "open_sources");
}

def test_v2_derives_clean_search_query_from_instructional_news_objective() {
    set_v2_fixture_io(True);
    result: dict[str, any] = run_helper_v2({
        "objective": "Search the web for the latest AI news and updates, gather multiple current sources, and summarize them. Do not summarize the current page."
    });
    set_v2_fixture_io(False);

    plan_execution: dict[str, any] = result.get("plan_execution", {}) if isinstance(result.get("plan_execution", {}), dict) else {};
    steps: list[any] = plan_execution.get("step_results", []) if isinstance(plan_execution.get("step_results", []), list) else [];
    first_step: dict[str, any] = steps[0] if len(steps) > 0 and isinstance(steps[0], dict) else {};
    provenance: list[any] = first_step.get("provenance", []) if isinstance(first_step.get("provenance", []), list) else [];
    query_used: str = "";
    if len(provenance) > 0 and isinstance(provenance[0], dict) {
        query_used = str(provenance[0].get("search_query", ""));
    }

    final_output: dict[str, any] = result.get("final_output", {}) if isinstance(result.get("final_output", {}), dict) else {};

    assert_eq(
        "v2 derived news query strips helper boilerplate",
        derive_external_search_query("Search the web for the latest AI news and updates, gather multiple current sources, and summarize them. Do not summarize the current page."),
        "the latest AI news and updates"
    );
    assert_eq("v2 load sources uses cleaned query", query_used, "the latest AI news and updates");
    assert_eq("v2 instructional objective still succeeds", str(final_output.get("status", "")), "success");
    assert_true("v2 instructional objective summary stays article grounded", "deployment controls" in str(final_output.get("summary", "")) or "rollout guardrails" in str(final_output.get("summary", "")));
}

def test_refuse_hub_only_path() {
    result: dict[str, any] = run_helper_v2({
        "objective": "Summarize recent AI news and updates",
        "search_results": SEARCH_RESULTS,
        "opened_pages": HUB_PAGES
    });

    final_output: dict[str, any] = result.get("final_output", {}) if isinstance(result.get("final_output", {}), dict) else {};
    summary: str = str(final_output.get("summary", ""));

    assert_eq("v2 hub-only path partial", str(final_output.get("status", "")), "partial");
    assert_eq("v2 hub-only reason explicit", str(final_output.get("reason", "")), "hub_only_sources");
    assert_true("v2 hub-only refusal text", "Refused synthesis" in summary);
    assert_true("v2 hub-only no sources emitted", len(final_output.get("sources", [])) == 0);
}

def test_honest_limited_summary_path() {
    result: dict[str, any] = run_helper_v2({
        "objective": "Summarize recent AI news and updates",
        "opened_pages": WEAK_PAGES
    });

    final_output: dict[str, any] = result.get("final_output", {}) if isinstance(result.get("final_output", {}), dict) else {};
    limitations: list[any] = final_output.get("limitations", []) if isinstance(final_output.get("limitations", []), list) else [];

    assert_eq("v2 weak-source path partial", str(final_output.get("status", "")), "partial");
    assert_eq("v2 weak-source reason explicit", str(final_output.get("reason", "")), "weak_sources");
    assert_true("v2 weak-source limited summary text", "Limited summary only." in str(final_output.get("summary", "")));
    assert_true("v2 weak-source notes mention no fallback", "No fallback summary was generated from hub pages or shell text." in limitations);
}

def test_structured_plan_execution_output() {
    session_id: str = "sess_v2_plan_" + str(time.time()).replace(".", "");
    write_trace(session_id, mk_trace(session_id));

    result: dict[str, any] = run_helper_v2({
        "objective": "Summarize what is happening on the current page",
        "browser_session_id": session_id
    });

    plan_execution: dict[str, any] = result.get("plan_execution", {}) if isinstance(result.get("plan_execution", {}), dict) else {};
    steps: list[any] = plan_execution.get("step_results", []) if isinstance(plan_execution.get("step_results", []), list) else [];

    assert_eq("v2 plan schema", str(plan_execution.get("schema", "")), "helpers_v2/plan_execution");
    assert_eq("v2 plan strategy", str(plan_execution.get("strategy", "")), "telemetry_first_read_only_v2");
    assert_true("v2 plan has three steps", len(steps) == 3);
    assert_true("v2 plan step has provenance", isinstance(steps[0].get("provenance", []), list));
    assert_true("v2 plan step has consumes", isinstance(steps[1].get("consumes", []), list));
    assert_eq("v2 current page plan uses load observation", str(steps[0].get("type", "")), "load_observation");
    assert_eq("v2 current page plan uses current page summarizer", str(steps[1].get("type", "")), "summarize_current_page");
}

def test_current_page_research_collects_supporting_links() {
    result: dict[str, any] = run_helper_v2({
        "objective": "Research the current page and extract useful links and findings",
        "trace_data": mk_trace("sess_v2_research_links")
    });

    generated_plan: list[any] = result.get("plan_execution", {}).get("generated_plan", []) if isinstance(result.get("plan_execution", {}).get("generated_plan", []), list) else [];
    sources: list[any] = result.get("final_output", {}).get("sources", []) if isinstance(result.get("final_output", {}).get("sources", []), list) else [];

    assert_true("v2 current page research plan has four steps", len(generated_plan) == 4);
    assert_eq("v2 current page research adds link collection", str(generated_plan[2].get("type", "")), "collect_supporting_links");
    assert_true("v2 current page research emits metrics link", "https://example.com/story/metrics-breakdown-2026-04-05" in str(sources));
}

def test_compare_sources_plan_adds_comparison_step() {
    result: dict[str, any] = run_helper_v2({
        "objective": "Compare a few sources and synthesize the differences",
        "opened_pages": ARTICLE_PAGES
    });

    generated_plan: list[any] = result.get("plan_execution", {}).get("generated_plan", []) if isinstance(result.get("plan_execution", {}).get("generated_plan", []), list) else [];
    highlights: list[any] = result.get("final_output", {}).get("highlights", []) if isinstance(result.get("final_output", {}).get("highlights", []), list) else [];

    assert_true("v2 compare sources plan has three steps", len(generated_plan) == 3);
    assert_eq("v2 compare sources starts with classification", str(generated_plan[0].get("type", "")), "classify_pages");
    assert_eq("v2 compare sources adds comparison step", str(generated_plan[1].get("type", "")), "compare_artifacts");
    assert_true("v2 compare sources highlights retain source-backed notes", len(highlights) >= 3);
}

def test_summarize_opened_pages_skips_search_and_compare() {
    result: dict[str, any] = run_helper_v2({
        "objective": "Summarize a set of already opened pages",
        "opened_pages": ARTICLE_PAGES
    });

    generated_plan: list[any] = result.get("plan_execution", {}).get("generated_plan", []) if isinstance(result.get("plan_execution", {}).get("generated_plan", []), list) else [];

    assert_true("v2 opened pages plan has two steps", len(generated_plan) == 2);
    assert_eq("v2 opened pages first step is classify pages", str(generated_plan[0].get("type", "")), "classify_pages");
    assert_eq("v2 opened pages second step is synthesize", str(generated_plan[1].get("type", "")), "synthesize");
}

def test_no_fallback_to_junk_summary_text() {
    result: dict[str, any] = run_helper_v2({
        "objective": "Summarize recent AI news and updates",
        "search_results": SEARCH_RESULTS,
        "opened_pages": HUB_PAGES
    });

    summary: str = str(result.get("final_output", {}).get("summary", ""));

    assert_eq("v2 junk summary avoids hub title", "AI News: Latest Machine Learning & Robotics Updates" in summary, False);
    assert_eq("v2 junk summary avoids google hub title", "Google News - Artificial intelligence - Latest" in summary, False);
    assert_eq("v2 junk summary avoids shell snippet", "Stay updated with the latest AI news and updates from around the industry." in summary, False);
}

def test_compare_current_runtime_vs_v2_for_same_news_task() {
    set_v2_fixture_io(True);
    os.environ["HELPER_SEARCH_WEB_FIXTURE_HTML"] = SEARCH_FIXTURE_HTML;
    os.environ["HELPER_OPEN_PAGE_FIXTURE_JSON"] = json.dumps(OPEN_PAGE_FIXTURE);

    suffix: str = str(time.time()).replace(".", "");
    create_result: dict[str, any] = create_helper({
        "name": "AI news compare " + suffix,
        "goal": "Summarize the latest AI news and updates",
        "frequency": "once",
        "runtime_version": "v1"
    });

    helper_id: str = str(create_result.get("helper_bundle", {}).get("helper", {}).get("helper_id", ""));
    current_result: dict[str, any] = run_helper_once({
        "helper_id": helper_id,
        "browser_state_hint": {
            "title": "Blank tab",
            "current_url": "https://example.com/"
        }
    });
    v2_result: dict[str, any] = run_helper_v2({
        "objective": "Summarize the latest AI news and updates"
    });

    set_v2_fixture_io(False);
    os.environ["HELPER_SEARCH_WEB_FIXTURE_HTML"] = "";
    os.environ["HELPER_OPEN_PAGE_FIXTURE_JSON"] = "";

    current_structured: dict[str, any] = current_result.get("run", {}).get("structured_output", {}) if isinstance(current_result.get("run", {}).get("structured_output", {}), dict) else {};
    current_sources: list[any] = current_structured.get("sources", []) if isinstance(current_structured.get("sources", []), list) else [];
    v2_sources: list[any] = v2_result.get("final_output", {}).get("sources", []) if isinstance(v2_result.get("final_output", {}).get("sources", []), list) else [];

    assert_true("compare current runtime ok", bool(current_result.get("ok", False)));
    assert_eq("compare current runtime status", str(current_result.get("run", {}).get("status", "")), "success");
    assert_eq("compare v2 runtime status", str(v2_result.get("final_output", {}).get("status", "")), "success");
    assert_true("compare current runtime has sources", len(current_sources) >= 2);
    assert_true("compare v2 runtime has sources", len(v2_sources) >= 2);
}

def test_inferred_plans_differ_without_modes() {
    news_blueprint: dict[str, any] = infer_execution_blueprint({
        "objective": "Summarize the latest AI news and updates"
    });
    current_page_blueprint: dict[str, any] = infer_execution_blueprint({
        "objective": "Summarize what is happening on the current page",
        "trace_data": mk_trace("sess_v2_blueprint")
    });
    current_page_research_blueprint: dict[str, any] = infer_execution_blueprint({
        "objective": "Research the current page and extract useful links and findings",
        "trace_data": mk_trace("sess_v2_blueprint_research")
    });
    compare_sources_blueprint: dict[str, any] = infer_execution_blueprint({
        "objective": "Compare a few sources and synthesize the differences",
        "opened_pages": ARTICLE_PAGES
    });
    opened_pages_blueprint: dict[str, any] = infer_execution_blueprint({
        "objective": "Summarize a set of already opened pages",
        "opened_pages": ARTICLE_PAGES
    });

    news_steps: list[any] = news_blueprint.get("plan", []) if isinstance(news_blueprint.get("plan", []), list) else [];
    current_page_steps: list[any] = current_page_blueprint.get("plan", []) if isinstance(current_page_blueprint.get("plan", []), list) else [];
    current_page_research_steps: list[any] = current_page_research_blueprint.get("plan", []) if isinstance(current_page_research_blueprint.get("plan", []), list) else [];
    compare_sources_steps: list[any] = compare_sources_blueprint.get("plan", []) if isinstance(compare_sources_blueprint.get("plan", []), list) else [];
    opened_pages_steps: list[any] = opened_pages_blueprint.get("plan", []) if isinstance(opened_pages_blueprint.get("plan", []), list) else [];

    assert_eq("v2 inferred news intent", str(news_blueprint.get("intent", {}).get("intent", "")), "cross_source_grounding");
    assert_eq("v2 inferred current page intent", str(current_page_blueprint.get("intent", {}).get("intent", "")), "current_page_grounding");
    assert_eq("v2 inferred news first step", str(news_steps[0].get("type", "")), "load_sources");
    assert_eq("v2 inferred current page first step", str(current_page_steps[0].get("type", "")), "load_observation");
    assert_eq("v2 inferred current page research third step", str(current_page_research_steps[2].get("type", "")), "collect_supporting_links");
    assert_eq("v2 inferred compare sources second step", str(compare_sources_steps[1].get("type", "")), "compare_artifacts");
    assert_eq("v2 inferred opened pages omits comparison", bool("compare_artifacts" in str(opened_pages_steps)), False);
    assert_eq(
        "v2 runtime result omits mode",
        bool("mode" in run_helper_v2({"objective": "Summarize the latest AI news and updates", "opened_pages": ARTICLE_PAGES})),
        False
    );
}

with entry {
    test_normalized_telemetry_state_shape();
    test_source_candidate_scoring();
    test_page_classification();
    test_inferred_plans_differ_without_modes();
    test_summarize_from_article_path();
    test_v2_real_io_fixture_path_for_news();
    test_v2_derives_clean_search_query_from_instructional_news_objective();
    test_refuse_hub_only_path();
    test_honest_limited_summary_path();
    test_structured_plan_execution_output();
    test_current_page_research_collects_supporting_links();
    test_compare_sources_plan_adds_comparison_step();
    test_summarize_opened_pages_skips_search_and_compare();
    test_no_fallback_to_junk_summary_text();
    test_compare_current_runtime_vs_v2_for_same_news_task();
    print("");
    print("Passed: " + str(COUNTS["passed"]));
    print("Failed: " + str(COUNTS["failed"]));
}
