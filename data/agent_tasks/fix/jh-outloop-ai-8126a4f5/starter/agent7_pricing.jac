"""Agent 7: Pricing Strategy Agent - Researches competitor pricing and designs a full pricing strategy per product."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import os;
import from env_loader { OPENAI_API_KEY }
import from agent6_business_orchestrator { BusinessProfile, run_business_analysis }

glob llm = Model(model_name="gpt-4o-mini", api_key=OPENAI_API_KEY);

glob AGENT6_CACHE_FILENAME: str = "agent6-result.json";

"""Complete pricing strategy for a software product."""
obj PricingStrategy {
    has software_name: str = "";
    has competitor_pricing: list[str] = [];
    has pricing_model: str = "";
    has price_point: str = "";
    has packaging_tiers: list[str] = [];
    has discounting_rules: list[str] = [];
    has price_sensitivity: str = "";
}

"""Generate a complete pricing strategy from a serialized BusinessProfile."""
def generate_pricing_strategy(profile_json: str) -> PricingStrategy by llm;

sem generate_pricing_strategy = """
You are a SaaS pricing strategist with deep experience in B2B software pricing. You will receive a JSON
business profile including the software's name, problem, description, market sizing (TAM/SAM/SOM,
addressable_accounts, icp_segments, avg_acv, market_growth_rate), and initial revenue model suggestions.

Produce a complete pricing strategy with the following fields:

competitor_pricing: Research and document 3-5 real or realistic competitors in this product's category.
  For each, specify their name, pricing model structure (per-seat / usage-based / flat-fee / % of spend),
  price points at each tier, and what is included. Also note where their pricing information comes from
  (website, G2 reviews, etc.). Format each entry as a single string:
  "Competitor Name | model: per-seat | Starter: $49/seat/mo (up to 5 users, core features) |
  Pro: $99/seat/mo (unlimited users, analytics, API) | source: company website + G2 reviews"

pricing_model: Recommend exactly one pricing model (per-seat, usage-based, flat-rate, tiered, or hybrid).
  Justify the choice by explaining how customers experience value from this specific product.
  If value scales with usage (e.g. API calls, transactions, documents processed), price on usage.
  If value scales with team size or seats, price per seat. If value is fixed and predictable, flat-rate.
  Explicitly reject the alternatives with brief reasons.

price_point: Set a specific price anchored to value delivered, not cost to serve. Follow this structure:
  1. Estimate the annual economic value to one customer (time saved × hourly rate, revenue unlocked,
     risk reduced, cost avoided) — show the calculation explicitly.
  2. Apply a value capture ratio (typically 10-20% of value delivered is a defensible price).
  3. Cross-check against the avg_acv from the market analysis — if they diverge significantly, explain why.
  4. State the recommended price point clearly (e.g. "$2,400/yr per seat" or "$499/mo flat").
  5. Include a suggested willingness-to-pay test question for early sales conversations.

packaging_tiers: Design exactly 2-3 tiers that capture different willingness-to-pay segments without
  overcomplicating the buying decision. For each tier specify: name, price, target customer type,
  and 3-5 included features or limits. Ensure each tier has a clear reason to upgrade to the next.
  Format each as a single string:
  "Starter | $X/mo | for [customer type] | includes: feature1, feature2, feature3 | limit: Y seats/users"

discounting_rules: Define exactly 5 firm discounting rules that prevent discount spirals. Cover:
  - Maximum discount per approval level (e.g. AE self-approves up to 10%, manager up to 20%, VP up to 30%)
  - What concession you always trade for a discount (annual prepay, multi-year contract, logo/case study rights,
    reference call commitment)
  - One hard floor you never go below regardless of deal size
  - One rule about when to walk away instead of discounting
  - One rule specific to competitive displacement deals
  Format each as a single actionable rule string starting with "RULE:".

price_sensitivity: Run the price sensitivity math in three steps:
  1. Baseline: use the som figure and avg_acv from the market analysis to calculate a target MRR/ARR.
     Show the formula: e.g. "Targeting 1% of SAM ($X) = $Y ARR → $Z MRR, needing N customers at $ACV avg ACV"
  2. Raise 20%: if you increase price by 20%, calculate how many customers you can afford to lose and still
     hit the same revenue target. Express as a percentage of your customer base.
  3. Drop 20%: if you decrease price by 20%, calculate how many additional customers you need to compensate.
     Assess whether that volume increase is realistic given your addressable_accounts count.
  4. Conclude with a calibration verdict: "Too low", "Too high", or "Well-calibrated", with one sentence of
     reasoning grounded in the math above.
""";

"""Serialize a BusinessProfile to a JSON string for LLM input."""
def serialize_business_profile(bp: BusinessProfile) -> str {
    item: Any = bp;
    return json.dumps(
        {
            "software_name": item.software_name,
            "problem": item.problem,
            "description": item.description,
            "market": {
                "tam_topdown": item.tam_topdown,
                "tam_bottomup": item.tam_bottomup,
                "sam": item.sam,
                "som": item.som,
                "addressable_accounts": item.addressable_accounts,
                "icp_segments": item.icp_segments,
                "avg_acv": item.avg_acv,
                "market_growth_rate": item.market_growth_rate
            },
            "revenue": {
                "business_model_type": item.business_model_type,
                "pricing_strategy": item.pricing_strategy,
                "revenue_streams": item.revenue_streams,
                "monthly_revenue_range": item.monthly_revenue_range
            }
        },
        indent=2
    );
}

"""Find agent6-result.json by checking CWD and the JackHacksproject subdirectory."""
def find_agent6_cache() -> str {
    candidates: list[str] = [
        AGENT6_CACHE_FILENAME,
        os.path.join("JackHacksproject", AGENT6_CACHE_FILENAME)
    ];
    for p in candidates {
        if os.path.exists(p) {
            return p;
        }
    }
    return "";
}

"""Load BusinessProfile objects from agent6-result.json cache file."""
def load_business_profiles_from_cache(cache_path: str) -> list[BusinessProfile] {
    f: Any = open(cache_path, "r");
    content: str = f.read();
    f.close();
    data: Any = json.loads(content);
    profiles: list[BusinessProfile] = [];
    for entry in data {
        m: Any = entry.get("market", {});
        r: Any = entry.get("revenue", {});
        profiles.append(
            BusinessProfile(
                software_name=entry.get("software_name", ""),
                problem=entry.get("problem", ""),
                description=entry.get("description", ""),
                tam_topdown=m.get("tam_topdown", ""),
                tam_bottomup=m.get("tam_bottomup", ""),
                sam=m.get("sam", ""),
                som=m.get("som", ""),
                addressable_accounts=m.get("addressable_accounts", ""),
                icp_segments=m.get("icp_segments", []),
                avg_acv=m.get("avg_acv", ""),
                market_growth_rate=m.get("market_growth_rate", ""),
                business_model_type=r.get("business_model_type", ""),
                pricing_strategy=r.get("pricing_strategy", ""),
                revenue_streams=r.get("revenue_streams", []),
                monthly_revenue_range=r.get("monthly_revenue_range", "")
            )
        );
    }
    return profiles;
}

"""Run pricing analysis: load business profiles from cache or Agent 6, then generate pricing strategy per product."""
def run_pricing_analysis() -> list[PricingStrategy] {
    profiles: list[BusinessProfile] = [];

    cache_path: str = find_agent6_cache();
    if cache_path != "" {
        print(f"PricingAgent: Found Agent 6 cache at '{cache_path}'. Loading business profiles...");
        profiles = load_business_profiles_from_cache(cache_path);
        print(f"PricingAgent: Loaded {len(profiles)} business profiles from cache.");
    }
    if len(profiles) == 0 {
        print("PricingAgent: No Agent 6 cache found. Running Agents 1-6...");
        profiles = run_business_analysis();
        print(f"PricingAgent: Received {len(profiles)} business profiles.");
    }

    strategies: list[PricingStrategy] = [];
    for bp in profiles {
        item: Any = bp;
        print(f"PricingAgent: Generating pricing strategy for '{item.software_name}'...");
        profile_json: str = serialize_business_profile(bp);
        strategy: PricingStrategy = generate_pricing_strategy(profile_json);
        s: Any = strategy;
        s.software_name = item.software_name;
        strategies.append(strategy);
    }
    return strategies;
}

walker PricingAgent {
    can run with Root entry {
        print("PricingAgent: Starting pricing strategy analysis...");
        strategies: list[PricingStrategy] = run_pricing_analysis();
        report strategies;
        print(
            f"PricingAgent: Completed pricing strategies for {len(strategies)} products."
        );
    }
}

with entry {
    result: Any = root() spawn PricingAgent();
    strategies: list[PricingStrategy] = result.reports[0];
    output: list[dict[str, Any]] = [];
    for ps in strategies {
        item: Any = ps;
        output.append(
            {
                "software_name": item.software_name,
                "competitor_pricing": item.competitor_pricing,
                "pricing_model": item.pricing_model,
                "price_point": item.price_point,
                "packaging_tiers": item.packaging_tiers,
                "discounting_rules": item.discounting_rules,
                "price_sensitivity": item.price_sensitivity
            }
        );
    }
    print("\n=== Agent 7 Output: Pricing Strategies ===");
    print(json.dumps(output, indent=2));
}
