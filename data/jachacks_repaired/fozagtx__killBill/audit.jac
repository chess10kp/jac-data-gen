"""Subscription & Bill Killer — agentic audit pipeline in Jac.

The deterministic CSV clustering lives in `recurrence.py`. Everything that
requires *judgment* (what is this merchant, is the price fair, is it being
used, should you cancel, what should the email say) runs through byLLM here,
and the orchestrator at the bottom lets the model pick tool order itself —
that's the agentic part the JacHacks judges are looking for.
"""
import os;
import json;
import re;
import from byllm.lib { Model }
import from recurrence { find_recurring }
import from concurrent.futures { ThreadPoolExecutor, as_completed }

# -------------------- LLM config --------------------
# Backend selection (in order of preference):
#   1. FEATHERLESS_API_KEY -> Qwen2.5-72B (free / recommended demo path)
#   2. ANTHROPIC_API_KEY   -> Claude Sonnet 4
#   3. OPENAI_API_KEY      -> gpt-4o-mini
#   4. GEMINI_API_KEY      -> Gemini 2.5 Flash
#
# Featherless is OpenAI-compatible — set OPENAI_API_BASE=https://api.featherless.ai/v1
# and OPENAI_API_KEY=$FEATHERLESS_API_KEY before running. The provided
# `run_demo.sh` does this for you.

def _pick_model() -> Model {
    if os.environ.get("FEATHERLESS_API_KEY") {
        # Default to Qwen2.5-14B (concurrency cost 1, ~5s/tool-call).
        # Override via SUBKILLER_MODEL — e.g. 'openai/Qwen/Qwen2.5-72B-Instruct'
        # for higher quality at higher latency.
        model_id = os.environ.get(
            "SUBKILLER_MODEL", "openai/Qwen/Qwen2.5-14B-Instruct"
        );
        return Model(
            model_name=model_id,
            api_key=os.environ.get("FEATHERLESS_API_KEY", "")
        );
    }
    if os.environ.get("ANTHROPIC_API_KEY") {
        return Model(model_name="claude-sonnet-4-20250514");
    }
    if os.environ.get("OPENAI_API_KEY") {
        return Model(model_name="gpt-4o-mini");
    }
    if os.environ.get("GEMINI_API_KEY") {
        return Model(model_name="gemini/gemini-2.5-flash");
    }
    raise Exception(
        "No LLM API key found. Set one of: FEATHERLESS_API_KEY (recommended), "
        "ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY. See README."
    );
}

glob llm = _pick_model();

# -------------------- node graph (persisted under root) --------------------
# Anything connected to `root` here auto-persists across runs via Jac's OSP.

node BankStatement {
    has source_path: str,
        total_recurring_charges: int = 0;
}

node Subscription {
    has merchant: str,
        monthly_cost: float,
        annual_cost: float,
        charge_count: int,
        charge_type: str = "OTHER";
}

node KillRecommendation {
    has verdict: str,                       # "KEEP" | "DOWNGRADE" | "CANCEL"
        reason: str,
        monthly_savings: float = 0.0,
        annual_savings: float = 0.0,
        cheaper_alternative: str = "";
}

node CancellationEmail {
    has subject: str,
        body: str,
        send_to: str;                       # e.g. "support@netflix.com / in-app account page"
}

# -------------------- LLM tools (called by the orchestrator agent) --------------------
# All return JSON-encoded strings. We parse them in Python. This sidesteps
# `response_format: json_schema` which some OpenAI-compatible backends
# (Featherless/vLLM) only partially support.

def enrich_merchant(raw_description: str, median_amount_usd: float) -> str by llm();
sem enrich_merchant = """Given a raw bank statement description and the monthly charge amount, return a JSON string (no markdown fence) with keys:
  - clean_name (string, e.g. 'Netflix')
  - category (one of: STREAMING, SAAS, UTILITY, INSURANCE, GYM, NEWS, CLOUD_STORAGE, TELECOM, AI_TOOL, NOT_A_SUBSCRIPTION, OTHER)
  - typical_price_usd (number, the typical going market price for this service per month)
  - notes (string, one-line context about what this service is)
Return ONLY the JSON object, no prose.""";

def judge_value(
    merchant: str,
    category: str,
    monthly_cost: float,
    months_active: int,
    other_subs_summary: str
) -> str by llm();
sem judge_value = """Decide whether the user should KEEP, DOWNGRADE, or CANCEL this subscription. Return a JSON string with:
  - verdict (one of: KEEP, DOWNGRADE, CANCEL)
  - reason (1-2 sentence plain-English explanation that references the user's other subscriptions when relevant)
Pick CANCEL when there is heavy overlap with another sub, the charge is far above market typical, or there is no evidence of use. Pick DOWNGRADE when a strictly cheaper tier of the same product would meet most needs. Pick KEEP for cheap essentials (under $5) or single-source services like phone or insurance. Return ONLY the JSON, no prose.""";

def find_cheaper_alternative(
    merchant: str,
    category: str,
    current_monthly_cost: float
) -> str by llm();
sem find_cheaper_alternative = """Suggest a cheaper alternative or lower tier of the same product. Return a JSON string with:
  - has_alternative (boolean)
  - suggestion (string, e.g. 'Netflix Premium $22.99 -> Netflix Standard with ads $6.99')
  - estimated_monthly_savings (number, USD)
If no realistic alternative exists return has_alternative=false and estimated_monthly_savings=0. Return ONLY the JSON.""";

def draft_cancellation_email(
    merchant: str,
    monthly_cost: float,
    category: str,
    months_active: int
) -> str by llm();
sem draft_cancellation_email = """Draft a polite, firm cancellation request. Return a JSON string with:
  - subject (string)
  - body (string, 4-7 sentences, first person, mentions wanting written confirmation of cancellation)
  - send_to (string, the most likely cancellation channel: an email address, support URL, or 'in-app account settings')
Return ONLY the JSON, no prose.""";

# -------------------- agentic orchestrator --------------------
# The wow moment: this single LLM call decides which tools to fire and in
# what order for each subscription. The outer Python loop only iterates over
# subs; the agent itself plans the audit of each one.

def analyze_one_subscription(
    raw_description: str,
    monthly_cost: float,
    months_active: int,
    other_subs_summary: str
) -> str
    by llm(
        tools=[
            enrich_merchant,
            judge_value,
            find_cheaper_alternative,
            draft_cancellation_email,
        ]
    );
sem analyze_one_subscription = """You are an agentic financial assistant auditing a single subscription. Decide which tools to call and in what order. A reasonable plan is:
  1. enrich_merchant to understand what this is and its typical market price
  2. judge_value to decide KEEP / DOWNGRADE / CANCEL
  3. if DOWNGRADE or CANCEL, call find_cheaper_alternative
  4. if CANCEL, call draft_cancellation_email
Skip steps when obvious (e.g. for KEEP you don't need the email).
Return the final answer as a JSON string (no markdown fence) with keys:
  - merchant (string, clean name)
  - category (string)
  - verdict (KEEP | DOWNGRADE | CANCEL)
  - reason (string)
  - monthly_cost (number)
  - monthly_savings (number, 0 if KEEP, monthly cost if CANCEL, current minus alternative if DOWNGRADE)
  - annual_savings (number, monthly_savings * 12)
  - cheaper_alternative (string, empty if KEEP)
  - email_subject (string, empty if not CANCEL)
  - email_body (string, empty if not CANCEL)
  - email_send_to (string, empty if not CANCEL)
Return ONLY the JSON object.""";

# -------------------- public Python-callable runner --------------------

# Best-effort extraction of the JSON object from an agent string output.
# Models sometimes wrap JSON in prose or markdown fences; this strips that.
def _parse_agent_json(s: str) -> dict {
    if not s {
        return {} ;
    }
    txt = s.strip();
    m = re.search(r"```(?:json)?\s*(\{.*?\})\s*```", txt, re.DOTALL);
    if m {
        txt = m.group(1);
    } else {
        start = txt.find("{");
        if start == -1 {
            return {} ;
        }
        depth = 0;
        end = -1;
        i = start;
        while i < len(txt) {
            ch = txt[i];
            if ch == "{" {
                depth += 1;
            } elif ch == "}" {
                depth -= 1;
                if depth == 0 {
                    end = i;
                    break;
                }
            }
            i += 1;
        }
        if end == -1 {
            return {} ;
        }
        txt = txt[start:end+1];
    }
    try {
        return json.loads(txt);
    } except Exception as e {
        return {} ;
    }
}

def audit_statement_path(path: str) -> dict {
    clusters = find_recurring(path);

    # Build a short summary of all monthly subs so each per-sub call has context.
    summary_lines = [];
    for c in clusters {
        monthly = -float(c["median_amount"]);
        if c["cadence_label"] == "monthly" {
            summary_lines.append(f"- {c['merchant_normalized']} ${monthly:.2f}/mo");
        }
    }
    others_summary = "\n".join(summary_lines);

    # Filter to monthly subs and run agent calls in parallel — slow LLM
    # backends like Featherless take 30s per call, so serialising 13 subs
    # blows past the demo budget. Each agent call is independent so a thread
    # pool fans out the I/O wait cleanly.
    monthly_subs = [c for c in clusters if c["cadence_label"] == "monthly"];

    def _run_one(c: dict) -> dict {
        monthly_cost = -float(c["median_amount"]);
        months_active = int(c["count"]);
        raw = c["raw_descriptions"][0] if c["raw_descriptions"] else c["merchant_normalized"];
        try {
            v_str = analyze_one_subscription(
                raw_description=raw,
                monthly_cost=monthly_cost,
                months_active=months_active,
                other_subs_summary=others_summary
            );
        } except Exception as e {
            return {"_skipped": True, "merchant": c["merchant_normalized"], "_err": str(e)};
        }
        v = _parse_agent_json(v_str);
        if not v {
            return {"_skipped": True, "merchant": c["merchant_normalized"], "_err": "no JSON in agent reply"};
        }
        v["merchant"] = v.get("merchant") or c["merchant_normalized"];
        v["verdict"] = (v.get("verdict") or "KEEP").upper();
        # Some models double-wrap the reason as another JSON object; unwrap it.
        raw_reason = v.get("reason") or "";
        if isinstance(raw_reason, str) and raw_reason.strip().startswith("{") {
            inner = _parse_agent_json(raw_reason);
            raw_reason = inner.get("reason") or inner.get("body") or raw_reason;
        }
        v["reason"] = raw_reason;
        # Same defensive unwrap for email_body
        eb = v.get("email_body") or "";
        if isinstance(eb, str) and eb.strip().startswith("{") {
            inner = _parse_agent_json(eb);
            eb = inner.get("body") or inner.get("email_body") or eb;
        }
        v["email_body"] = eb;
        v["monthly_cost"] = float(v.get("monthly_cost") or monthly_cost);
        v["monthly_savings"] = float(v.get("monthly_savings") or 0.0);
        v["annual_savings"] = float(v.get("annual_savings") or v["monthly_savings"] * 12);
        v["cheaper_alternative"] = v.get("cheaper_alternative") or "";
        v["email_subject"] = v.get("email_subject") or "";
        v["email_send_to"] = v.get("email_send_to") or "";
        return v;
    }

    verdicts = [];
    max_workers = int(os.environ.get("SUBKILLER_MAX_WORKERS", "6"));
    print(f"  Running agent on {len(monthly_subs)} subscriptions ({max_workers} in parallel)...");
    with ThreadPoolExecutor(max_workers=max_workers) as pool {
        p: any = pool;
        futures = {p.submit(_run_one, c): c for c in monthly_subs};
        for fut in as_completed(futures) {
            c = futures[fut];
            v = fut.result();
            if v.get("_skipped") {
                print(f"     X skipped {v['merchant']}: {v.get('_err')}");
                continue;
            }
            tag = v["verdict"];
            sym = "X" if tag == "CANCEL" else ("~" if tag == "DOWNGRADE" else "o");
            print(f"     {sym} [{tag}] {v['merchant']}  save ${v['monthly_savings']:.2f}/mo");
            verdicts.append(v);
        }
    }

    total_monthly = sum([v["monthly_savings"] for v in verdicts]);
    return {
        "source": path,
        "subscriptions": verdicts,
        "monthly_savings": round(total_monthly, 2),
        "annual_savings": round(total_monthly * 12, 2),
        "subscription_count": len(verdicts),
    };
}

# -------------------- graph persistence helper --------------------

def persist_audit_to_graph(audit: dict) {
    stmt = BankStatement(
        source_path=audit["source"],
        total_recurring_charges=audit["subscription_count"]
    );
    root ++> stmt;
    for v in audit["subscriptions"] {
        sub = Subscription(
            merchant=str(v["merchant"]),
            monthly_cost=float(v["monthly_cost"]),
            annual_cost=float(v["monthly_cost"]) * 12,
            charge_count=0,
            charge_type=str(v.get("category", "OTHER"))
        );
        stmt ++> sub;
        rec = KillRecommendation(
            verdict=str(v["verdict"]),
            reason=str(v["reason"]),
            monthly_savings=float(v["monthly_savings"]),
            annual_savings=float(v["annual_savings"]),
            cheaper_alternative=str(v["cheaper_alternative"])
        );
        sub ++> rec;
        if v["email_subject"] {
            em = CancellationEmail(
                subject=str(v["email_subject"]),
                body=str(v["email_body"]),
                send_to=str(v["email_send_to"])
            );
            sub ++> em;
        }
    }
}

# -------------------- walker (becomes REST endpoint under `jac serve`) --------------------
# POST /walker/AuditStatement with either {"csv_path": "..."} or
# {"csv_text": "date,description,amount\n..."}. The response is in
# `reports[0]` per Jac's walker convention.

import tempfile;

walker:pub AuditStatement {
    has csv_path: str = "samples/statement_001.csv";
    has csv_text: str = "";
    has persist: bool = False;
    has reports: list[dict] = [];

    can run with Root entry {
        # If the client sent CSV text inline, write it to a temp file and
        # point the recurrence detector at it. This lets the frontend let
        # users drop their own statement without us hosting file uploads.
        path = self.csv_path;
        if self.csv_text {
            tf = tempfile.NamedTemporaryFile(
                mode="w", suffix=".csv", delete=False, encoding="utf-8"
            );
            tf.write(self.csv_text);
            tf.close();
            path = tf.name;
        }
        audit = audit_statement_path(path);
        if self.persist {
            persist_audit_to_graph(audit);
        }
        report audit;
    }
}
