"""
Jac helper backend layer tests.

Run with: jac run jac/helpers_test.jac
These tests verify helper/spec persistence, browser-state normalization,
and the plan-driven read-only helper runtime path.
"""

import time;
import os;
import json;
import from jac.layers.helpers {
    create_helper,
    get_helper,
    list_helpers,
    run_helper_once,
    list_helper_runs,
    get_helper_run,
    normalize_browser_state_from_trace,
    normalize_helper_definition,
    execute_plan_step,
    clean_html_text,
    derive_search_query
}
import from jac.layers.observation { write_trace }

glob COUNTS: dict[str, int] = {"passed": 0, "failed": 0};
glob SEARCH_FIXTURE_HTML: str = (
    "<html><body>" +
    "<div class=\"result results_links\">" +
    "<a class=\"result__a\" href=\"https://example.com/ai-news/\">AI News: Latest Machine Learning &amp; Robotics Updates</a>" +
    "<a class=\"result__snippet\">Stay updated with the latest AI news and updates from around the industry.</a>" +
    "</div>" +
    "<div class=\"result results_links\">" +
    "<a class=\"result__a\" href=\"https://www.engadget.com/ai/\">AI | Engadget</a>" +
    "<a class=\"result__snippet\">The latest AI news, reviews, and updates from Engadget.</a>" +
    "</div>" +
    "<div class=\"result results_links\">" +
    "<a class=\"result__a\" href=\"https://www.reuters.com/technology/openai-ships-lower-latency-enterprise-tools-2026-04-05/\">OpenAI ships lower-latency enterprise tools</a>" +
    "<a class=\"result__snippet\">Reuters reports OpenAI released new deployment controls and lower-latency multimodal tooling for enterprises.</a>" +
    "</div>" +
    "<div class=\"result results_links\">" +
    "<a class=\"result__a\" href=\"https://www.pcmag.com/news/meta-launches-new-agent-tooling-for-developers\">Meta launches new agent tooling for developers</a>" +
    "<a class=\"result__snippet\">PCMag says the release adds debugging controls, rollout guardrails, and workflow automation features.</a>" +
    "</div>" +
    "<div class=\"result results_links\">" +
    "<a class=\"result__a\" href=\"https://example.com/news/2026/04/05/policy-disclosures-for-frontier-models\">Regulators discuss frontier-model disclosure rules</a>" +
    "<a class=\"result__snippet\">Policy groups focused on safety reporting, transparency, and disclosure expectations for large-model deployments.</a>" +
    "</div>" +
    "<div class=\"result results_links\">" +
    "<a class=\"result__a\" href=\"https://example.com/story/cloud-inference-expansion-helps-ai-rollouts\">Cloud inference expansion helps AI rollouts</a>" +
    "<a class=\"result__snippet\">Cloud vendors announced new inference clusters and serving options for evaluation and deployment workloads.</a>" +
    "</div>" +
    "</body></html>"
);
glob OPEN_PAGE_FIXTURE: dict[str, any] = {
    "https://example.com/ai-news/": {
        "http_status": 200,
        "content_type": "text/html; charset=utf-8",
        "body": (
            "<html><head><title>AI News: Latest Machine Learning &amp; Robotics Updates</title>" +
            "<script>window.dataLayer=[{\"page\":\"ai-news\"}];function boot(){return true;}</script>" +
            "<style>.hero{font-family:Inter;} .page{display:block;}</style></head><body>" +
            "<header>AI News hub</header><main><h1>AI News: Latest Machine Learning &amp; Robotics Updates</h1>" +
            "<p>Stay updated with the latest AI news and updates from around the industry.</p></main>" +
            "</body></html>"
        )
    },
    "https://www.engadget.com/ai/": {
        "http_status": 200,
        "content_type": "text/html; charset=utf-8",
        "body": (
            "<html><head><title>AI | Engadget</title><script>WebFont.load({google:{families:['Open Sans']}});</script></head><body>" +
            "<nav>AI coverage</nav><section><h1>AI | Engadget</h1><p>The latest AI news and analysis.</p></section>" +
            "</body></html>"
        )
    },
    "https://www.reuters.com/technology/openai-ships-lower-latency-enterprise-tools-2026-04-05/": {
        "http_status": 200,
        "content_type": "text/html; charset=utf-8",
        "body": (
            "<html><head><title>OpenAI ships lower-latency enterprise tools</title><script>window.dataLayer.push({event:'page'});</script></head><body>" +
            "<article><h1>OpenAI ships lower-latency enterprise tools</h1>" +
            "<p>OpenAI introduced lower-latency multimodal models and new enterprise deployment controls for production teams.</p>" +
            "<p>Executives said the update improves tool use and rollout governance for customer-facing workflows.</p></article>" +
            "</body></html>"
        )
    },
    "https://www.pcmag.com/news/meta-launches-new-agent-tooling-for-developers": {
        "http_status": 200,
        "content_type": "text/html; charset=utf-8",
        "body": (
            "<html><head><title>Meta launches new agent tooling for developers</title></head><body>" +
            "<article><h1>Meta launches new agent tooling for developers</h1>" +
            "<p>Meta launched new debugging controls, rollout guardrails, and agent workflow automation features for developers.</p>" +
            "<p>The release focuses on safer deployments and better observability for production assistants.</p></article>" +
            "</body></html>"
        )
    },
    "https://example.com/news/2026/04/05/policy-disclosures-for-frontier-models": {
        "http_status": 200,
        "content_type": "text/html; charset=utf-8",
        "body": (
            "<html><head><title>Regulators discuss frontier-model disclosure rules</title></head><body>" +
            "<section><h1>Regulators discuss frontier-model disclosure rules</h1>" +
            "<p>Policy groups focused on safety reporting, transparency, and disclosure expectations for large-model deployments.</p>" +
            "<p>Regulators discussed how labs should document incident response and model evaluation evidence.</p></section>" +
            "</body></html>"
        )
    },
    "https://example.com/story/cloud-inference-expansion-helps-ai-rollouts": {
        "http_status": 200,
        "content_type": "text/html; charset=utf-8",
        "body": (
            "<html><head><title>Cloud inference expansion helps AI rollouts</title></head><body>" +
            "<section><h1>Cloud inference expansion helps AI rollouts</h1>" +
            "<p>Cloud vendors expanded inference clusters and managed serving options for evaluation and deployment workloads.</p>" +
            "<p>Teams highlighted lower queuing delays and better capacity planning for enterprise launches.</p></section>" +
            "</body></html>"
        )
    }
};

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

def list_contains_text(values: any, expected: str) -> bool {
    if not isinstance(values, list) {
        return False;
    }

    for value in values {
        if str(value) == expected {
            return True;
        }
    }
    return False;
}

def plan_has_step_type(plan: any, expected_type: str) -> bool {
    if not isinstance(plan, list) {
        return False;
    }

    for step in plan {
        if not isinstance(step, dict) {
            continue;
        }
        if str(step.get("type", "")) == expected_type {
            return True;
        }
    }
    return False;
}

def unique_string_count(values: any) -> int {
    if not isinstance(values, list) {
        return 0;
    }

    seen: list[str] = [];
    for value in values {
        text: str = str(value);
        if text and text not in seen {
            seen.append(text);
        }
    }
    return len(seen);
}

def source_href_count(values: any) -> int {
    if not isinstance(values, list) {
        return 0;
    }

    seen: list[str] = [];
    for value in values {
        if not isinstance(value, dict) {
            continue;
        }
        href: str = str(value.get("href", ""));
        if href and href not in seen {
            seen.append(href);
        }
    }
    return len(seen);
}

def list_contains_substring(values: any, expected: str) -> bool {
    if not isinstance(values, list) {
        return False;
    }

    for value in values {
        if expected in str(value) {
            return True;
        }
    }
    return False;
}

def set_search_fixture_enabled(enabled: bool) {
    if enabled {
        os.environ["HELPER_SEARCH_WEB_FIXTURE_HTML"] = SEARCH_FIXTURE_HTML;
    } else {
        os.environ["HELPER_SEARCH_WEB_FIXTURE_HTML"] = "";
    }
}

def set_open_page_fixture_enabled(enabled: bool) {
    if enabled {
        os.environ["HELPER_OPEN_PAGE_FIXTURE_JSON"] = json.dumps(OPEN_PAGE_FIXTURE);
    } else {
        os.environ["HELPER_OPEN_PAGE_FIXTURE_JSON"] = "";
    }
}

"""R: Build a unique suffix for persisted helper test records.
M: Uses the current epoch seconds with dots removed so repeated test runs do not collide.
E: Collisions are still theoretically possible under extreme concurrency but unlikely in desktop tests.
"""
def unique_suffix() -> str {
    return str(time.time()).replace(".", "");
}

"""R: Build one telemetry-rich trace fixture for helper runtime and normalization tests.
M: Fills the same fields used by the observation layer's latest semantic/DOM/session seams.
E: Keeps the payload compact while still exercising headings, forms, links, and action extraction.
"""
def mk_helper_trace(session_id: str) -> dict[str, any] {
    return {
        "session_id": session_id,
        "title": "Helper Test Trace",
        "source_url": "https://example.com/research",
        "status": "stopped",
        "started_at": "2026-04-05T00:00:00Z",
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
            "body_text_sample": "Revenue increased by 18 percent year over year across the core product line.",
            "headings": ["Quarterly report", "Key metrics"],
            "forms": [
                {
                    "method": "GET",
                    "action": "/search",
                    "field_count": 1,
                    "submit_text": "Search",
                    "labels": ["Search reports"],
                    "path": "body > main > form"
                }
            ],
            "buttons": [
                {"text": "Download report", "label": "Download report", "path": "body > main > button.download"},
                {"text": "Open details", "label": "Open details", "path": "body > main > button.details"}
            ],
            "links": [
                {"text": "Investor relations", "href": "https://example.com/investors", "path": "body > main > a.investors"},
                {"text": "Metrics breakdown", "href": "https://example.com/metrics", "path": "body > main > a.metrics"}
            ]
        },
        "latest_session_state": {
            "origin": "https://example.com",
            "pathname": "/research",
            "cookie_count": 1,
            "local_storage": {"count": 0, "keys": []},
            "session_storage": {"count": 0, "keys": []}
        },
        "events": [
            {
                "type": "navigate",
                "url": "https://example.com/research",
                "recorded_at": "2026-04-05T00:00:20Z"
            },
            {
                "type": "page_ready",
                "url": "https://example.com/research",
                "recorded_at": "2026-04-05T00:00:50Z"
            }
        ]
    };
}

def helper_id_from_bundle(bundle: dict[str, any]) -> str {
    helper: any = bundle.get("helper", {});
    if isinstance(helper, dict) {
        return str(helper.get("helper_id", ""));
    }
    return "";
}

def run_id_from_run(run_record: dict[str, any]) -> str {
    return str(run_record.get("run_id", ""));
}

def list_contains_helper(list_result: dict[str, any], helper_id: str) -> bool {
    raw_helpers: any = list_result.get("helpers", []);
    if not isinstance(raw_helpers, list) {
        return False;
    }

    for bundle in raw_helpers {
        if not isinstance(bundle, dict) {
            continue;
        }
        if helper_id_from_bundle(bundle) == helper_id {
            return True;
        }
    }
    return False;
}

def test_create_and_get_helper() {
    suffix: str = unique_suffix();
    result: dict[str, any] = create_helper({
        "name": "Daily brief " + suffix,
        "goal": "Summarize the page and provide a short briefing.",
        "frequency": "daily"
    });

    assert_true("create helper ok", bool(result.get("ok", False)));
    bundle: dict[str, any] = result.get("helper_bundle", {});
    helper_id: str = helper_id_from_bundle(bundle);
    spec: dict[str, any] = bundle.get("agent_spec", {}) if isinstance(bundle, dict) else {};

    assert_true("create helper id present", helper_id != "");
    assert_eq("create helper frequency preserved", str(bundle.get("helper", {}).get("frequency", "")), "daily");
    assert_eq("create helper runtime version persisted", str(bundle.get("helper", {}).get("runtime_version", "")), "v2");
    assert_eq("create helper kind inferred", str(spec.get("kind", "")), "briefing");
    assert_eq("create helper runtime mode", str(spec.get("runtime_mode", "")), "browser_read");
    assert_eq("create helper read only", bool(spec.get("read_only", False)), True);
    assert_eq("create helper requirement current page", bool(spec.get("requirements", {}).get("needs_current_page_context", False)), True);
    assert_eq("create helper requirement search", bool(spec.get("requirements", {}).get("needs_search", True)), False);
    assert_true("create helper has observe capability", list_contains_text(spec.get("capabilities", []), "observe_browser"));
    assert_true("create helper has summarize capability", list_contains_text(spec.get("capabilities", []), "summarize"));
    assert_true("create helper plan has observe step", plan_has_step_type(spec.get("plan", []), "observe_browser"));
    assert_true("create helper plan has summarize step", plan_has_step_type(spec.get("plan", []), "summarize"));

    get_result: dict[str, any] = get_helper({"helper_id": helper_id});
    assert_true("get helper ok", bool(get_result.get("ok", False)));
    fetched_bundle: dict[str, any] = get_result.get("helper_bundle", {});
    assert_eq("get helper round-trips id", helper_id_from_bundle(fetched_bundle), helper_id);

    list_result: dict[str, any] = list_helpers({});
    assert_true("list helpers ok", bool(list_result.get("ok", False)));
    assert_true("list helpers includes created helper", list_contains_helper(list_result, helper_id));
}

"""R: Verify helper persistence stores explicit runtime selection and keeps older records safe by default.
M: Creates one briefing helper and normalizes one legacy helper record missing the field to confirm both paths resolve cleanly.
E: Legacy records should default to `v1` instead of auto-promoting into the new runtime.
"""
def test_helper_runtime_version_persistence_and_legacy_default() {
    create_result: dict[str, any] = create_helper({
        "name": "Runtime persistence " + unique_suffix(),
        "goal": "Summarize the page and provide a short briefing.",
        "frequency": "once"
    });

    helper: dict[str, any] = create_result.get("helper_bundle", {}).get("helper", {}) if isinstance(create_result.get("helper_bundle", {}).get("helper", {}), dict) else {};
    legacy_helper: dict[str, any] = normalize_helper_definition({
        "helper_id": "helper_legacy_runtime",
        "name": "Legacy helper",
        "goal": "Summarize the page and provide a short briefing.",
        "frequency": "once",
        "created_at": "2026-04-05T00:00:00Z",
        "updated_at": "2026-04-05T00:00:00Z",
        "status": "active",
        "agent_spec_id": "spec_legacy_runtime"
    });

    assert_true("runtime persistence create ok", bool(create_result.get("ok", False)));
    assert_eq("runtime persistence stored v2 for new briefing helper", str(helper.get("runtime_version", "")), "v2");
    assert_eq("runtime persistence legacy default is v1", str(legacy_helper.get("runtime_version", "")), "v1");
}

def test_normalize_browser_state_from_trace() {
    trace_data: dict[str, any] = mk_helper_trace("sess_state_" + unique_suffix());
    state: dict[str, any] = normalize_browser_state_from_trace(trace_data, {});

    assert_eq("normalize state current domain", str(state.get("current_domain", "")), "example.com");
    assert_eq("normalize state title", str(state.get("title", "")), "Example Research Page");
    assert_true("normalize state has visible actions", len(state.get("visible_actions", [])) >= 2);
    assert_true("normalize state has candidate links", len(state.get("candidate_links", [])) >= 2);
    assert_true("normalize state has extracted text", len(state.get("extracted_text_blocks", [])) >= 1);
}

def test_run_helper_once_with_trace() {
    suffix: str = unique_suffix();
    create_result: dict[str, any] = create_helper({
        "name": "Research helper " + suffix,
        "goal": "Research the current page and extract useful links and findings.",
        "frequency": "once"
    });

    assert_true("create helper for run ok", bool(create_result.get("ok", False)));
    helper_bundle: dict[str, any] = create_result.get("helper_bundle", {});
    helper_id: str = helper_id_from_bundle(helper_bundle);
    session_id: str = "sess_helper_run_" + suffix;
    write_trace(session_id, mk_helper_trace(session_id));

    run_result: dict[str, any] = run_helper_once({
        "helper_id": helper_id,
        "browser_session_id": session_id,
        "run_goal_override": "Focus on links worth revisiting later."
    });

    assert_true("run helper once ok", bool(run_result.get("ok", False)));
    run_record: dict[str, any] = run_result.get("run", {});
    structured_output: dict[str, any] = run_record.get("structured_output", {}) if isinstance(run_record, dict) else {};

    assert_eq("run helper status success", str(run_record.get("status", "")), "success");
    assert_eq("run helper runtime version stays v1", str(helper_bundle.get("helper", {}).get("runtime_version", "")), "v1");
    assert_eq("run helper browser session persisted", str(run_record.get("browser_session_id", "")), session_id);
    assert_eq("run helper state source trace", str(structured_output.get("state_source", "")), "trace");
    assert_eq("run helper execution strategy", str(run_record.get("runtime_state", {}).get("execution_strategy", "")), "agent_plan");
    assert_eq("run helper plan strategy", str(structured_output.get("plan_execution", {}).get("strategy", "")), "agent_plan");
    assert_true("run helper findings populated", len(structured_output.get("findings", [])) >= 1);
    assert_true("run helper browser state embedded", isinstance(structured_output.get("browser_state", {}), dict));
    assert_true("run helper plan has extract links step", plan_has_step_type(structured_output.get("plan", []), "extract_links"));

    runs_result: dict[str, any] = list_helper_runs({"helper_id": helper_id});
    assert_true("list helper runs ok", bool(runs_result.get("ok", False)));
    assert_true("list helper runs includes new run", len(runs_result.get("runs", [])) >= 1);

    run_id: str = run_id_from_run(run_record);
    get_run_result: dict[str, any] = get_helper_run({"run_id": run_id});
    assert_true("get helper run ok", bool(get_run_result.get("ok", False)));
    assert_eq("get helper run id round-trip", run_id_from_run(get_run_result.get("run", {})), run_id);
}

"""R: Verify runtime dispatch stays reversible across helpers of the same safe type.
M: Creates one eligible briefing helper forced onto v1 and one default briefing helper on v2, then checks each run path.
E: The dispatcher must respect persisted helper runtime selection rather than re-inferring at run time.
"""
def test_dispatcher_respects_v1_and_v2_runtime_selection() {
    v1_create: dict[str, any] = create_helper({
        "name": "Briefing stays v1 " + unique_suffix(),
        "goal": "Summarize the latest AI news and updates",
        "frequency": "once",
        "runtime_version": "v1"
    });
    v2_create: dict[str, any] = create_helper({
        "name": "Briefing moves v2 " + unique_suffix(),
        "goal": "Summarize the latest AI news and updates",
        "frequency": "once"
    });

    v1_bundle: dict[str, any] = v1_create.get("helper_bundle", {}) if isinstance(v1_create.get("helper_bundle", {}), dict) else {};
    v2_bundle: dict[str, any] = v2_create.get("helper_bundle", {}) if isinstance(v2_create.get("helper_bundle", {}), dict) else {};
    v1_run: dict[str, any] = run_helper_once({
        "helper_id": helper_id_from_bundle(v1_bundle),
        "browser_state_hint": {
            "title": "Blank tab",
            "current_url": "https://example.com/"
        }
    });
    v2_run: dict[str, any] = run_helper_once({
        "helper_id": helper_id_from_bundle(v2_bundle),
        "browser_state_hint": {
            "title": "Blank tab",
            "current_url": "https://example.com/"
        }
    });

    assert_true("dispatcher v1 helper run ok", bool(v1_run.get("ok", False)));
    assert_true("dispatcher v2 helper run ok", bool(v2_run.get("ok", False)));
    assert_eq("dispatcher v1 helper persisted v1", str(v1_bundle.get("helper", {}).get("runtime_version", "")), "v1");
    assert_eq("dispatcher v2 helper persisted v2", str(v2_bundle.get("helper", {}).get("runtime_version", "")), "v2");
    assert_eq("dispatcher picks v1 strategy", str(v1_run.get("run", {}).get("runtime_state", {}).get("execution_strategy", "")), "agent_plan");
    assert_eq("dispatcher picks v2 strategy", str(v2_run.get("run", {}).get("runtime_state", {}).get("execution_strategy", "")), "telemetry_first_read_only_v2");
}

"""R: Verify the new v2 briefing slice runs through the v2 runtime while non-briefing helpers remain on v1.
M: Runs a default briefing helper and a read-only research helper, then checks the strategy-specific output contracts.
E: The research helper should remain on v1 even though it is read-only, keeping the migration narrow.
"""
def test_v2_briefing_slice_only_routes_briefing_helpers() {
    set_search_fixture_enabled(True);
    set_open_page_fixture_enabled(True);

    briefing_create: dict[str, any] = create_helper({
        "name": "Briefing v2 slice " + unique_suffix(),
        "goal": "Summarize the latest AI news and updates",
        "frequency": "once"
    });
    research_create: dict[str, any] = create_helper({
        "name": "Research stays v1 " + unique_suffix(),
        "goal": "Research the current page and extract useful links and findings.",
        "frequency": "once"
    });

    session_id: str = "sess_runtime_slice_" + unique_suffix();
    write_trace(session_id, mk_helper_trace(session_id));

    briefing_run: dict[str, any] = run_helper_once({
        "helper_id": helper_id_from_bundle(briefing_create.get("helper_bundle", {}) if isinstance(briefing_create.get("helper_bundle", {}), dict) else {}),
        "browser_state_hint": {
            "title": "Blank tab",
            "current_url": "https://example.com/"
        }
    });
    research_run: dict[str, any] = run_helper_once({
        "helper_id": helper_id_from_bundle(research_create.get("helper_bundle", {}) if isinstance(research_create.get("helper_bundle", {}), dict) else {}),
        "browser_session_id": session_id
    });

    briefing_structured: dict[str, any] = briefing_run.get("run", {}).get("structured_output", {}) if isinstance(briefing_run.get("run", {}).get("structured_output", {}), dict) else {};
    research_structured: dict[str, any] = research_run.get("run", {}).get("structured_output", {}) if isinstance(research_run.get("run", {}).get("structured_output", {}), dict) else {};

    assert_true("briefing slice run ok", bool(briefing_run.get("ok", False)));
    assert_true("research slice run ok", bool(research_run.get("ok", False)));
    assert_eq("briefing slice persisted v2", str(briefing_create.get("helper_bundle", {}).get("helper", {}).get("runtime_version", "")), "v2");
    assert_eq("research slice persisted v1", str(research_create.get("helper_bundle", {}).get("helper", {}).get("runtime_version", "")), "v1");
    assert_eq("briefing slice uses v2 strategy", str(briefing_run.get("run", {}).get("runtime_state", {}).get("execution_strategy", "")), "telemetry_first_read_only_v2");
    assert_eq("briefing slice exposes v2 runtime version", str(briefing_structured.get("runtime_version", "")), "v2");
    assert_eq("briefing slice exposes v2 plan strategy", str(briefing_structured.get("plan_execution", {}).get("strategy", "")), "telemetry_first_read_only_v2");
    assert_true("briefing slice sources present", len(briefing_structured.get("sources", [])) >= 2);
    assert_eq("research slice stays on v1 strategy", str(research_run.get("run", {}).get("runtime_state", {}).get("execution_strategy", "")), "agent_plan");
    assert_true("research slice keeps v1 browser state output", isinstance(research_structured.get("browser_state", {}), dict));

    set_search_fixture_enabled(False);
    set_open_page_fixture_enabled(False);
}

def test_latest_news_helper_plan_blocks_honestly() {
    set_search_fixture_enabled(True);
    set_open_page_fixture_enabled(True);
    suffix: str = unique_suffix();
    create_result: dict[str, any] = create_helper({
        "name": "AI news " + suffix,
        "goal": "Summarize the latest AI news and updates",
        "frequency": "once",
        "runtime_version": "v1"
    });

    assert_true("create latest news helper ok", bool(create_result.get("ok", False)));
    helper_bundle: dict[str, any] = create_result.get("helper_bundle", {});
    helper_id: str = helper_id_from_bundle(helper_bundle);
    spec: dict[str, any] = helper_bundle.get("agent_spec", {}) if isinstance(helper_bundle, dict) else {};

    assert_eq("latest news freshness required", bool(spec.get("requirements", {}).get("freshness_required", False)), True);
    assert_eq("latest news needs search", bool(spec.get("requirements", {}).get("needs_search", False)), True);
    assert_eq("latest news needs multi source synthesis", bool(spec.get("requirements", {}).get("needs_multi_source_synthesis", False)), True);
    assert_eq("latest news needs current page context", bool(spec.get("requirements", {}).get("needs_current_page_context", True)), False);
    assert_true("latest news has search capability", list_contains_text(spec.get("capabilities", []), "search_web"));
    assert_true("latest news has rank capability", list_contains_text(spec.get("capabilities", []), "rank_sources"));
    assert_true("latest news has search step", plan_has_step_type(spec.get("plan", []), "search_web"));
    assert_true("latest news has open step", plan_has_step_type(spec.get("plan", []), "open_page"));
    assert_true("latest news contract requires sources", list_contains_text(spec.get("output_contract", {}).get("required_fields", []), "sources"));
    assert_eq("latest news helper pinned to v1", str(helper_bundle.get("helper", {}).get("runtime_version", "")), "v1");

    run_result: dict[str, any] = run_helper_once({
        "helper_id": helper_id,
        "browser_state_hint": {
            "title": "Google",
            "current_url": "https://www.google.com/"
        }
    });

    assert_true("run latest news helper ok", bool(run_result.get("ok", False)));
    run_record: dict[str, any] = run_result.get("run", {});
    structured_output: dict[str, any] = run_record.get("structured_output", {}) if isinstance(run_record, dict) else {};
    summary: str = str(structured_output.get("summary", ""));
    highlights: any = structured_output.get("highlights", []);
    sources: any = structured_output.get("sources", []);
    search_results: any = structured_output.get("search_results", []);
    limitations: any = structured_output.get("limitations", []);
    constraints: dict[str, any] = structured_output.get("constraints", {}) if isinstance(structured_output.get("constraints", {}), dict) else {};
    rank_step_output: dict[str, any] = structured_output.get("plan_execution", {}).get("step_results", [])[1].get("output", {}) if isinstance(structured_output.get("plan_execution", {}).get("step_results", [])[1].get("output", {}), dict) else {};
    ranked_sources: any = rank_step_output.get("sources", []);

    assert_eq("run latest news helper success", str(run_record.get("status", "")), "success");
    assert_eq("run latest news execution strategy", str(run_record.get("runtime_state", {}).get("execution_strategy", "")), "agent_plan");
    assert_eq("run latest news plan status success", str(structured_output.get("plan_execution", {}).get("status", "")), "success");
    assert_eq("run latest news search step success", str(structured_output.get("plan_execution", {}).get("step_results", [])[0].get("status", "")), "success");
    assert_eq("run latest news rank step success", str(structured_output.get("plan_execution", {}).get("step_results", [])[1].get("status", "")), "success");
    assert_eq("run latest news open step success", str(structured_output.get("plan_execution", {}).get("step_results", [])[2].get("status", "")), "success");
    assert_eq("run latest news first blocked step empty", str(structured_output.get("plan_execution", {}).get("first_blocked_step", {}).get("type", "")), "");
    assert_eq("run latest news blocked reason empty", str(structured_output.get("plan_execution", {}).get("blocked_reason", "")), "");
    assert_true("run latest news captures search results", len(structured_output.get("search_results", [])) >= 2);
    assert_true("run latest news captures source snippets", str(structured_output.get("search_results", [])[0].get("snippet", "")) != "");
    assert_true("run latest news captures opened pages", len(structured_output.get("opened_pages", [])) >= 2);
    assert_true("run latest news captures extracted pages", len(structured_output.get("extracted_pages", [])) >= 2);
    assert_true("run latest news step result opened pages present", len(structured_output.get("plan_execution", {}).get("step_results", [])[2].get("output", {}).get("opened_pages", [])) >= 2);
    assert_eq("run latest news rank avoids hub first result", str(ranked_sources[0].get("href", "")) == "https://example.com/ai-news/" or str(ranked_sources[0].get("href", "")) == "https://www.engadget.com/ai/", False);
    assert_true("run latest news summary concise", len(summary) <= 240);
    assert_eq("run latest news summary avoids old top-source phrasing", "Top source:" in summary, False);
    assert_eq("run latest news avoids google fallback", "Google" in summary, False);
    assert_eq("run latest news summary avoids hub title recap", "AI News: Latest Machine Learning & Robotics Updates" in summary, False);
    assert_true("run latest news summary uses article content", "safety reporting" in summary or "deployment controls" in summary or "inference clusters" in summary or "agent tooling" in summary);
    assert_true("run latest news highlights bounded", len(highlights) <= int(constraints.get("max_output_items", 5)));
    assert_eq("run latest news highlights unique", unique_string_count(highlights), len(highlights));
    assert_true("run latest news sources present", len(sources) >= 1);
    assert_eq("run latest news sources trimmed to max_sources", len(sources), int(constraints.get("max_sources", 5)));
    assert_eq("run latest news search results trimmed to max_sources", len(search_results), int(constraints.get("max_sources", 5)));
    assert_eq("run latest news source hrefs unique", source_href_count(sources), len(sources));
    assert_true("run latest news findings bounded", len(structured_output.get("findings", [])) <= 3);
    assert_true("run latest news freshness limitation present", list_contains_substring(limitations, "Freshness was requested"));
    assert_eq("run latest news page summary concise", len(str(structured_output.get("page_summary", ""))) <= 320, True);
    set_search_fixture_enabled(False);
    set_open_page_fixture_enabled(False);
}

def test_rank_sources_prefers_reporting_articles_over_hubs() {
    rank_result: dict[str, any] = execute_plan_step(
        {},
        {},
        {},
        "",
        "none",
        {"step_id": "rank_sources", "type": "rank_sources", "params": {"top_k": 3}},
        {
            "sources": [
                {
                    "href": "https://news.google.com/topics/CAAqJggKIiBDQkFTRWdvSkwyMHZNRFZxYUdjU0FtVnVLQUFQAQ",
                    "text": "Google News - Artificial intelligence - Latest",
                    "domain": "news.google.com",
                    "snippet": "Get the latest Artificial intelligence news and updates."
                },
                {
                    "href": "https://www.reuters.com/technology/openai-released-new-enterprise-tools-2026-04-05/",
                    "text": "OpenAI released new enterprise tools today",
                    "domain": "www.reuters.com",
                    "snippet": "Reuters reports the company announced new deployment controls and enterprise updates."
                },
                {
                    "href": "https://www.pcmag.com/news/new-ai-release-adds-agent-workflows",
                    "text": "New AI release adds agent workflows",
                    "domain": "www.pcmag.com",
                    "snippet": "PCMag says the release adds agent workflow updates and debugging tools."
                },
                {
                    "href": "https://example.com/category/ai",
                    "text": "AI News",
                    "domain": "example.com",
                    "snippet": "Stay updated with the latest."
                }
            ]
        }
    );

    ranked_sources: list[any] = rank_result.get("output", {}).get("sources", []) if isinstance(rank_result.get("output", {}), dict) else [];

    assert_eq("rank sources step success", str(rank_result.get("status", "")), "success");
    assert_true("rank sources returns requested count", len(ranked_sources) == 3);
    assert_eq("rank sources promotes Reuters article", str(ranked_sources[0].get("domain", "")), "www.reuters.com");
    assert_eq("rank sources promotes second article over hubs", str(ranked_sources[1].get("domain", "")), "www.pcmag.com");
    assert_eq("rank sources keeps Google News hub out of top two", str(ranked_sources[0].get("domain", "")) == "news.google.com" or str(ranked_sources[1].get("domain", "")) == "news.google.com", False);
}

def test_clean_html_text_removes_script_payloads() {
    cleaned: str = clean_html_text(
        "<html><head><script>window.dataLayer=[{\"event\":\"page\"}];</script>" +
        "<style>.hero{font-family:Inter;}</style></head><body>" +
        "<main><h1>OpenAI ships lower-latency enterprise tools</h1>" +
        "<p>OpenAI introduced lower-latency multimodal models for production teams.</p>" +
        "<p>WebFont.load({google:{families:['Open Sans']}});</p></main></body></html>",
        320
    );

    assert_eq("clean html strips window datalayer", "window.dataLayer" in cleaned, False);
    assert_eq("clean html strips webfont payload", "WebFont.load" in cleaned, False);
    assert_true("clean html keeps readable article text", "lower-latency multimodal models" in cleaned);
}

"""R: Verify helper creation collapses accidental duplicated instruction prefixes before persistence and planning.
M: Creates a helper with a repeated leading clause and asserts the stored goal and search query are both normalized once.
E: The normalization should keep the user’s subject intact rather than truncating the final constraint phrase.
"""
def test_create_helper_normalizes_duplicated_goal_text() {
    duplicated_goal: str = (
        "Summarize the latest AI news and updates from current web sources, not " +
        "Summarize the latest AI news and updates from current web sources, not the current page."
    );
    create_result: dict[str, any] = create_helper({
        "name": "Duplicate goal normalization " + unique_suffix(),
        "goal": duplicated_goal,
        "frequency": "once"
    });

    bundle: dict[str, any] = create_result.get("helper_bundle", {}) if isinstance(create_result.get("helper_bundle", {}), dict) else {};
    helper: dict[str, any] = bundle.get("helper", {}) if isinstance(bundle.get("helper", {}), dict) else {};
    spec: dict[str, any] = bundle.get("agent_spec", {}) if isinstance(bundle.get("agent_spec", {}), dict) else {};
    normalized_goal: str = "Summarize the latest AI news and updates from current web sources, not the current page.";

    assert_true("duplicate goal helper create ok", bool(create_result.get("ok", False)));
    assert_eq("duplicate goal helper stored once", str(helper.get("goal", "")), normalized_goal);
    assert_eq("duplicate goal spec goal_text stored once", str(spec.get("goal_text", "")), normalized_goal);
    assert_eq("duplicate goal objective stored once", str(spec.get("objective", {}).get("primary_goal", "")), normalized_goal);
    assert_eq("duplicate goal derived query cleaned", derive_search_query(duplicated_goal), "the latest AI news and updates");
}

def test_summarize_marks_hub_heavy_pages_limited() {
    summarize_result: dict[str, any] = execute_plan_step(
        {},
        {},
        {},
        "",
        "none",
        {"step_id": "summarize", "type": "summarize", "params": {"max_items": 3, "max_chars": 220}},
        {
            "extracted_pages": [
                {
                    "url": "https://example.com/ai-news/",
                    "title": "AI News: Latest Machine Learning & Robotics Updates",
                    "domain": "example.com",
                    "content_excerpt": "Stay updated with the latest AI news and updates from around the industry.",
                    "status": "success"
                },
                {
                    "url": "https://news.google.com/topics/CAAqJggKIiBDQkFTRWdvSkwyMHZNRFZxYUdjU0FtVnVLQUFQAQ",
                    "title": "Google News - Artificial intelligence - Latest",
                    "domain": "news.google.com",
                    "content_excerpt": "Get the latest Artificial intelligence news and updates.",
                    "status": "success"
                }
            ]
        }
    );

    summary_output: dict[str, any] = summarize_result.get("output", {}) if isinstance(summarize_result.get("output", {}), dict) else {};
    preview: str = str(summary_output.get("summary_preview", ""));

    assert_eq("summarize hub-heavy inputs partial", str(summarize_result.get("status", "")), "partial");
    assert_true("summarize hub-heavy inputs honest preview", "no reliable summary could be produced" in preview);
}

"""R: Verify that provider error pages are excluded from limited summarize previews and highlight output.
M: Passes a DuckDuckGo-style error excerpt plus a generic landing page and asserts the fallback stays clean and highlight-free.
E: The result should remain partial and honest even when every fetched page is unusable.
"""
def test_summarize_excludes_error_page_junk() {
    summarize_result: dict[str, any] = execute_plan_step(
        {},
        {},
        {},
        "",
        "none",
        {"step_id": "summarize", "type": "summarize", "params": {"max_items": 3, "max_chars": 220}},
        {
            "extracted_pages": [
                {
                    "url": "https://duckduckgo.com/?q=latest+ai+news",
                    "title": "DuckDuckGo",
                    "domain": "duckduckgo.com",
                    "content_excerpt": "Oops, there was an error. Please try again later.",
                    "status": "success"
                },
                {
                    "url": "https://recentai.news/",
                    "title": "Latest AI News",
                    "domain": "recentai.news",
                    "content_excerpt": "Stay updated with the latest AI news and updates from around the industry.",
                    "status": "success"
                }
            ]
        }
    );

    output: dict[str, any] = summarize_result.get("output", {}) if isinstance(summarize_result.get("output", {}), dict) else {};
    preview: str = str(output.get("summary_preview", ""));
    highlights: list[any] = output.get("highlights", []) if isinstance(output.get("highlights", []), list) else [];

    assert_eq("error-like summarize is partial", str(summarize_result.get("status", "")), "partial");
    assert_eq("error-like preview excludes oops", "Oops, there was an error." in preview, False);
    assert_true("error-like preview uses honest limitation", "no reliable summary could be produced" in preview);
    assert_eq("error-like highlights empty", len(highlights), 0);
}

"""R: Verify that marketing-heavy AI news landing pages do not become summarize previews.
M: Uses a Crescendo-style title and tagline so the shared low-signal filter must reject both title and excerpt.
E: The preview should stay limitation-focused rather than echoing slogans or year-based roundup copy.
"""
def test_summarize_excludes_marketing_news_hub_text() {
    summarize_result: dict[str, any] = execute_plan_step(
        {},
        {},
        {},
        "",
        "none",
        {"step_id": "summarize", "type": "summarize", "params": {"max_items": 3, "max_chars": 220}},
        {
            "extracted_pages": [
                {
                    "url": "https://www.crescendo.ai/news/latest-ai-news-and-updates",
                    "title": "Latest AI News and AI Breakthroughs that Matter Most: 2026",
                    "domain": "www.crescendo.ai",
                    "content_excerpt": "News CRESCENDO LIVE - Step into the future of CX with the latest AI news and AI breakthroughs that matter most.",
                    "status": "success"
                }
            ]
        }
    );

    output: dict[str, any] = summarize_result.get("output", {}) if isinstance(summarize_result.get("output", {}), dict) else {};
    preview: str = str(output.get("summary_preview", ""));

    assert_eq("marketing hub summarize partial", str(summarize_result.get("status", "")), "partial");
    assert_eq("marketing hub preview excludes title recap", "Latest AI News and AI Breakthroughs that Matter Most: 2026" in preview, False);
    assert_eq("marketing hub preview excludes tagline", "Step into the future of CX" in preview, False);
    assert_true("marketing hub preview uses limited wording", "no reliable summary could be produced" in preview);
}

"""R: Verify summarize can fall back to grounded source snippets when fetched page text is unavailable.
M: Passes empty extracted pages plus ranked source snippets so the step must return a limited but informative preview.
E: Junk snippets should still be excluded, so the preview must mention only concrete reporting details.
"""
def test_summarize_uses_grounded_source_snippet_fallback() {
    summarize_result: dict[str, any] = execute_plan_step(
        {},
        {},
        {},
        "",
        "none",
        {"step_id": "summarize", "type": "summarize", "params": {"max_items": 3, "max_chars": 220}},
        {
            "sources": [
                {
                    "href": "https://duckduckgo.com/y.js?ad_domain=example.com&ad_provider=bingv7aa",
                    "text": "Instant AI Detection",
                    "domain": "duckduckgo.com",
                    "snippet": "AI",
                    "rank": 1
                },
                {
                    "href": "https://www.reuters.com/technology/openai-ships-lower-latency-enterprise-tools-2026-04-05/",
                    "text": "OpenAI ships lower-latency enterprise tools",
                    "domain": "www.reuters.com",
                    "snippet": "Reuters reports OpenAI released new deployment controls and lower-latency multimodal tooling for enterprises.",
                    "rank": 2
                },
                {
                    "href": "https://www.pcmag.com/news/meta-launches-new-agent-tooling-for-developers",
                    "text": "Meta launches new agent tooling for developers",
                    "domain": "www.pcmag.com",
                    "snippet": "PCMag says the release adds debugging controls, rollout guardrails, and workflow automation features.",
                    "rank": 3
                }
            ]
        }
    );

    output: dict[str, any] = summarize_result.get("output", {}) if isinstance(summarize_result.get("output", {}), dict) else {};
    preview: str = str(output.get("summary_preview", ""));
    highlights: list[any] = output.get("highlights", []) if isinstance(output.get("highlights", []), list) else [];

    assert_eq("snippet fallback summarize partial", str(summarize_result.get("status", "")), "partial");
    assert_true("snippet fallback preview uses grounded detail", "deployment controls" in preview or "rollout guardrails" in preview);
    assert_eq("snippet fallback preview excludes ad junk", "Instant AI Detection" in preview, False);
    assert_true("snippet fallback highlights present", len(highlights) >= 1);
}

"""R: Verify that a section-front page from a known publisher ranks below a specific dated article from the same publisher.
M: Uses a Reuters AI section URL vs a Reuters dated article URL so the ranking signal is generic path-shape, not domain.
E: Generic section pages should lose regardless of publisher reputation because page shape is the primary synthesis signal.
"""
def test_section_page_loses_to_same_publisher_article() {
    rank_result: dict[str, any] = execute_plan_step(
        {},
        {},
        {},
        "",
        "none",
        {"step_id": "rank_sources", "type": "rank_sources", "params": {"top_k": 2}},
        {
            "sources": [
                {
                    "href": "https://www.reuters.com/technology/artificial-intelligence/",
                    "text": "Artificial Intelligence | Reuters",
                    "domain": "www.reuters.com",
                    "snippet": "The latest artificial intelligence news, analysis and coverage from Reuters."
                },
                {
                    "href": "https://www.reuters.com/technology/artificial-intelligence/openai-cuts-api-costs-2026-04-04/",
                    "text": "OpenAI cuts API costs for enterprise customers",
                    "domain": "www.reuters.com",
                    "snippet": "Reuters reports OpenAI announced significant API pricing reductions for enterprise and startup accounts."
                }
            ]
        }
    );

    ranked: list[any] = rank_result.get("output", {}).get("sources", []) if isinstance(rank_result.get("output", {}), dict) else [];

    assert_eq("section vs article rank success", str(rank_result.get("status", "")), "success");
    assert_true("section vs article has two results", len(ranked) == 2);
    assert_eq(
        "dated article ranks above same-publisher section front",
        str(ranked[0].get("href", "")),
        "https://www.reuters.com/technology/artificial-intelligence/openai-cuts-api-costs-2026-04-04/"
    );
    assert_eq(
        "section front is ranked second not first",
        str(ranked[1].get("href", "")),
        "https://www.reuters.com/technology/artificial-intelligence/"
    );
}

"""R: Verify that summarize produces a substantive multi-sentence briefing when given multiple usable article pages.
M: Passes three concrete article pages from different domains and checks that the preview contains content from at least two sources.
E: The preview should contain 2 or more sentence boundaries and mention concrete developments, not hub-style copy.
"""
def test_summarize_multi_sentence_from_article_pages() {
    summarize_result: dict[str, any] = execute_plan_step(
        {},
        {},
        {},
        "",
        "none",
        {"step_id": "summarize", "type": "summarize", "params": {"max_items": 5, "max_chars": 220}},
        {
            "extracted_pages": [
                {
                    "url": "https://www.reuters.com/technology/cybersecurity/data-breach-millions-2026-04-03/",
                    "title": "Data breach exposes millions of customer records",
                    "domain": "www.reuters.com",
                    "content_excerpt": "A major data breach exposed millions of customer records.",
                    "status": "success"
                },
                {
                    "url": "https://www.theverge.com/2026/4/3/ai-disclosure-rules",
                    "title": "New disclosure rules target frontier AI systems",
                    "domain": "www.theverge.com",
                    "content_excerpt": "Regulators issued disclosure rules targeting frontier AI systems.",
                    "status": "success"
                },
                {
                    "url": "https://techcrunch.com/2026/04/03/startup-raises-funding-inference/",
                    "title": "Startup raises funding for enterprise inference capacity",
                    "domain": "techcrunch.com",
                    "content_excerpt": "A startup secured funding for enterprise inference capacity.",
                    "status": "success"
                }
            ]
        }
    );

    status: str = str(summarize_result.get("status", ""));
    output: dict[str, any] = summarize_result.get("output", {}) if isinstance(summarize_result.get("output", {}), dict) else {};
    preview: str = str(output.get("summary_preview", ""));
    period_count: int = preview.count(".");

    assert_eq("multi article summarize success", status, "success");
    assert_eq("multi article not hub limited", bool(output.get("coverage_limited", False)), False);
    assert_true("multi article preview has first development", "data breach" in preview or "millions" in preview);
    assert_true("multi article preview has second development", "disclosure" in preview or "inference" in preview or "startup" in preview);
    assert_true("multi article preview is multi-sentence", period_count >= 2);
    assert_eq("multi article usable count", int(output.get("usable_source_count", 0) if isinstance(output.get("usable_source_count", 0), int) else 0), 3);
}

"""R: Verify that plan-driven partial summaries use clean briefing language when only junk source pages are fetched.
M: Runs a latest-news helper against fixtures containing only a provider error page and a marketing/news landing page.
E: The final helper summary should stay partial and honest without surfacing legacy browser-read phrasing.
"""
def test_execute_agent_plan_partial_uses_briefing_language() {
    os.environ["HELPER_SEARCH_WEB_FIXTURE_HTML"] = (
        "<html><body>" +
        "<div class=\"result results_links\">" +
        "<a class=\"result__a\" href=\"https://duckduckgo.com/?q=latest+ai+news\">DuckDuckGo</a>" +
        "<a class=\"result__snippet\">Oops, there was an error. Please try again...</a>" +
        "</div>" +
        "<div class=\"result results_links\">" +
        "<a class=\"result__a\" href=\"https://www.crescendo.ai/news/latest-ai-news-and-updates\">Latest AI News and AI Breakthroughs that Matter Most: 2026</a>" +
        "<a class=\"result__snippet\">News CRESCENDO LIVE - Step into the future of CX!</a>" +
        "</div>" +
        "</body></html>"
    );
    os.environ["HELPER_OPEN_PAGE_FIXTURE_JSON"] = json.dumps({
        "https://duckduckgo.com/?q=latest+ai+news": {
            "http_status": 200,
            "content_type": "text/html; charset=utf-8",
            "body": (
                "<html><head><title>DuckDuckGo</title></head><body>" +
                "<main><p>Oops, there was an error. Please try again later.</p></main>" +
                "</body></html>"
            )
        },
        "https://www.crescendo.ai/news/latest-ai-news-and-updates": {
            "http_status": 200,
            "content_type": "text/html; charset=utf-8",
            "body": (
                "<html><head><title>Latest AI News and AI Breakthroughs that Matter Most: 2026</title></head><body>" +
                "<main><h1>Latest AI News and AI Breakthroughs that Matter Most: 2026</h1>" +
                "<p>News CRESCENDO LIVE - Step into the future of CX with the latest AI news and updates.</p></main>" +
                "</body></html>"
            )
        }
    });

    suffix: str = unique_suffix();
    create_result: dict[str, any] = create_helper({
        "name": "Weak AI news " + suffix,
        "goal": "Summarize the latest AI news and updates",
        "frequency": "once",
        "runtime_version": "v1"
    });
    helper_bundle: dict[str, any] = create_result.get("helper_bundle", {}) if isinstance(create_result.get("helper_bundle", {}), dict) else {};
    helper_id: str = helper_id_from_bundle(helper_bundle);

    run_result: dict[str, any] = run_helper_once({
        "helper_id": helper_id,
        "browser_state_hint": {
            "title": "Search",
            "current_url": "https://duckduckgo.com/"
        }
    });

    run_record: dict[str, any] = run_result.get("run", {}) if isinstance(run_result.get("run", {}), dict) else {};
    structured_output: dict[str, any] = run_record.get("structured_output", {}) if isinstance(run_record.get("structured_output", {}), dict) else {};
    summary: str = str(structured_output.get("summary", ""));
    page_summary: str = str(structured_output.get("page_summary", ""));
    highlights: list[any] = structured_output.get("highlights", []) if isinstance(structured_output.get("highlights", []), list) else [];

    assert_eq("partial weak-source helper status", str(run_record.get("status", "")), "partial");
    assert_true("partial weak-source summary uses briefing prefix", "Partial briefing." in summary);
    assert_eq("partial weak-source avoids browser read wording", "Partial browser read snapshot." in summary, False);
    assert_eq("partial weak-source avoids error text", "Oops, there was an error." in summary or "Oops, there was an error." in page_summary, False);
    assert_eq("partial weak-source avoids marketing title", "Latest AI News and AI Breakthroughs that Matter Most: 2026" in summary or "Latest AI News and AI Breakthroughs that Matter Most: 2026" in page_summary, False);
    assert_eq("partial weak-source highlights empty", len(highlights), 0);

    os.environ["HELPER_SEARCH_WEB_FIXTURE_HTML"] = "";
    os.environ["HELPER_OPEN_PAGE_FIXTURE_JSON"] = "";
}

"""R: Verify that generic hub patterns from diverse domains are penalized relative to a concrete dated article.
M: Tests section-front, aggregation-URL, and topic-category pages against a TechCrunch article to confirm generic ranking behavior.
E: No single domain should be hardcoded; the heuristics must work for URLs from any publisher.
"""
def test_rank_broader_hub_patterns_penalized() {
    rank_result: dict[str, any] = execute_plan_step(
        {},
        {},
        {},
        "",
        "none",
        {"step_id": "rank_sources", "type": "rank_sources", "params": {"top_k": 3}},
        {
            "sources": [
                {
                    "href": "https://www.sciencedaily.com/news/computers_math/artificial_intelligence/",
                    "text": "Artificial Intelligence News - ScienceDaily",
                    "domain": "www.sciencedaily.com",
                    "snippet": "Read the latest artificial intelligence research news."
                },
                {
                    "href": "https://www.crescendo.ai/news/latest-ai-news-and-updates",
                    "text": "Latest AI News and AI Breakthroughs that Matter Most: 2026",
                    "domain": "www.crescendo.ai",
                    "snippet": "Latest AI news and AI breakthroughs that matter most: 2026 | CRESCENDO LIVE"
                },
                {
                    "href": "https://techcrunch.com/2026/04/04/anthropic-expands-model-context-capacity/",
                    "text": "Anthropic expands model context capacity for enterprise",
                    "domain": "techcrunch.com",
                    "snippet": "Anthropic announced expanded context windows and fine-tuning support for Claude enterprise deployments."
                }
            ]
        }
    );

    ranked: list[any] = rank_result.get("output", {}).get("sources", []) if isinstance(rank_result.get("output", {}), dict) else [];

    assert_eq("broader hub patterns rank success", str(rank_result.get("status", "")), "success");
    assert_true("broader hub patterns returns 3 results", len(ranked) == 3);
    assert_eq("dated article beats section and aggregation hubs", str(ranked[0].get("domain", "")), "techcrunch.com");
    assert_eq("sciencedaily category page not ranked first", str(ranked[0].get("href", "")) == "https://www.sciencedaily.com/news/computers_math/artificial_intelligence/", False);
    assert_eq("crescendo aggregation page not ranked first", str(ranked[0].get("href", "")) == "https://www.crescendo.ai/news/latest-ai-news-and-updates", False);
}

with entry {
    test_create_and_get_helper();
    test_helper_runtime_version_persistence_and_legacy_default();
    test_normalize_browser_state_from_trace();
    test_run_helper_once_with_trace();
    test_dispatcher_respects_v1_and_v2_runtime_selection();
    test_v2_briefing_slice_only_routes_briefing_helpers();
    test_rank_sources_prefers_reporting_articles_over_hubs();
    test_clean_html_text_removes_script_payloads();
    test_summarize_marks_hub_heavy_pages_limited();
    test_summarize_excludes_error_page_junk();
    test_summarize_excludes_marketing_news_hub_text();
    test_latest_news_helper_plan_blocks_honestly();
    test_section_page_loses_to_same_publisher_article();
    test_summarize_multi_sentence_from_article_pages();
    test_execute_agent_plan_partial_uses_briefing_language();
    test_rank_broader_hub_patterns_penalized();
    print("");
    print("Passed: " + str(COUNTS["passed"]));
    print("Failed: " + str(COUNTS["failed"]));
}
