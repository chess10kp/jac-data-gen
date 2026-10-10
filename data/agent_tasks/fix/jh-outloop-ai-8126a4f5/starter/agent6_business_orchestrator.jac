"""Agent 6: Business Orchestrator - Runs market sizing and revenue model analysis per software idea from Agent 5."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import os;
import from env_loader { OPENAI_API_KEY }
import from agent4_problem_creator { run_problem_creation, ProblemStatement }
import from agent5_software_prompt { SoftwarePrompt, generate_software_prompts, serialize_problems }

glob AGENT5_CACHE_FILENAME: str = "agent5-result.json";

glob llm = Model(model_name="gpt-4o-mini", api_key=OPENAI_API_KEY);

"""Rigorous market sizing for a software product using TAM/SAM/SOM and bottom-up account counting."""
obj MarketAnalysis {
    has tam_topdown: str = "";
    has tam_bottomup: str = "";
    has sam: str = "";
    has som: str = "";
    has addressable_accounts: str = "";
    has icp_segments: list[str] = [];
    has avg_acv: str = "";
    has market_growth_rate: str = "";
}

"""Revenue and business model for a software product."""
obj RevenueModel {
    has business_model_type: str = "";
    has pricing_strategy: str = "";
    has revenue_streams: list[str] = [];
    has monthly_revenue_range: str = "";
}

"""Full business profile combining software description, market sizing, and revenue model."""
obj BusinessProfile {
    has software_name: str = "";
    has problem: str = "";
    has description: str = "";
    has tam_topdown: str = "";
    has tam_bottomup: str = "";
    has sam: str = "";
    has som: str = "";
    has addressable_accounts: str = "";
    has icp_segments: list[str] = [];
    has avg_acv: str = "";
    has market_growth_rate: str = "";
    has business_model_type: str = "";
    has pricing_strategy: str = "";
    has revenue_streams: list[str] = [];
    has monthly_revenue_range: str = "";
}

"""Perform rigorous TAM/SAM/SOM sizing and ICP account analysis for a software product described as JSON."""
def analyze_market(software_json: str) -> MarketAnalysis by llm;

sem analyze_market = """
You are a venture-grade market analyst. You will receive a JSON description of a software product.
Perform a rigorous market sizing analysis and return the following fields:

TAM — Total Addressable Market: the global revenue if every possible buyer purchased this product.
  - tam_topdown: cite a real industry report or analyst estimate (e.g. "Global workflow automation market: $26B in 2024
    per MarketsandMarkets, growing to $78B by 2030"). If no exact figure is known, estimate from adjacent categories.
  - tam_bottomup: independently derive TAM from first principles: estimate the total number of potential buyers
    worldwide × a realistic annual price per buyer. Show your math inline (e.g. "~4M SMB ops teams globally × $2K ACV
    = $8B"). Both methods should converge within an order of magnitude.

SAM — Serviceable Addressable Market: the slice of TAM reachable given the product's go-to-market model,
  geography, language, and distribution. This is narrower than TAM. Give a dollar figure and explain the filter
  applied (e.g. "English-speaking markets, self-serve SaaS: ~$1.2B").

SOM — Serviceable Obtainable Market: what a well-executed team could realistically capture in 2–3 years,
  given competitive dynamics and realistic sales capacity. Give a dollar figure and a brief rationale
  (e.g. "0.5% of SAM in year 3 = $6M ARR — achievable with a 10-person sales team and strong PLG motion").

ICP Account Sizing — do NOT just cite a Gartner number. Count actual addressable accounts:
  - addressable_accounts: estimate the total number of companies or users that match the ICP, with a breakdown
    (e.g. "~3,500 mid-market fintechs (100–1000 employees), ~22,000 SMB fintechs globally").
  - icp_segments: list 3–5 specific ICP segments, each with an estimated account count and a one-line description
    (e.g. "Mid-market logistics companies (500–2000 employees): ~8,000 globally").

Deal Economics:
  - avg_acv: estimate a realistic Annual Contract Value per customer based on the product's features, buyer persona,
    and competitive pricing. Show the logic (e.g. "SMB buyers in this category pay $1,200–$3,600/yr; use $2,400 ACV").

Market Velocity:
  - market_growth_rate: state the annual market growth rate as a percentage and explain what it means strategically
    (e.g. "28% CAGR — fast-growing market means demand is being created; less need to steal share from incumbents").

Be specific, quantitative, and show your reasoning inline within each field. Avoid vague phrases like
'large and growing market' without numbers to back them up.
""";

"""Given a software description and its market analysis, propose a revenue and business model."""
def generate_revenue_model(software_json: str, market_json: str) -> RevenueModel by llm;

sem generate_revenue_model = """
You are a business strategist specializing in software monetization. You will receive:
1. A JSON description of a software product (name, problem, features, tech stack)
2. A JSON market analysis including TAM/SAM/SOM figures, ICP segments, addressable account count, avg_acv,
   and market growth rate.

Use the market sizing data — especially avg_acv and addressable_accounts — to ground your recommendations:
- business_model_type: the primary model (e.g. "B2B SaaS", "Freemium", "Marketplace", "Usage-based")
- pricing_strategy: concrete tier structure anchored to the avg_acv from the market analysis
  (e.g. "Tiered subscription: $99/mo SMB, $499/mo Mid-Market, $2K/mo Enterprise — aligns with $2,400 avg ACV")
- revenue_streams: list of 2-4 distinct revenue streams tied to the ICP segments identified
  (e.g. subscriptions, professional services, API access, marketplace fees)
- monthly_revenue_range: derive a realistic year-1 MRR range from the SOM figure
  (e.g. "SOM of $3M ARR in year 3 implies $250K MRR; early-stage year 1 target: $15K-$50K MRR")

Show the math connecting the market sizing inputs to your revenue projections.
""";

"""Serialize a SoftwarePrompt to a JSON string for LLM input."""
def serialize_software_prompt(sp: SoftwarePrompt) -> str {
    item: Any = sp;
    return json.dumps(
        {
            "software_name": item.software_name,
            "problem": item.problem,
            "description": item.description,
            "core_features": item.core_features,
            "tech_stack": item.tech_stack,
            "score": item.score
        },
        indent=2
    );
}

"""Serialize a MarketAnalysis to a JSON string for LLM input."""
def serialize_market(market: MarketAnalysis) -> str {
    item: Any = market;
    return json.dumps(
        {
            "tam_topdown": item.tam_topdown,
            "tam_bottomup": item.tam_bottomup,
            "sam": item.sam,
            "som": item.som,
            "addressable_accounts": item.addressable_accounts,
            "icp_segments": item.icp_segments,
            "avg_acv": item.avg_acv,
            "market_growth_rate": item.market_growth_rate
        },
        indent=2
    );
}

"""Find agent5-result.json by checking CWD and the JackHacksproject subdirectory."""
def find_agent5_cache() -> str {
    candidates: list[str] = [
        AGENT5_CACHE_FILENAME,
        os.path.join("JackHacksproject", AGENT5_CACHE_FILENAME)
    ];
    for p in candidates {
        if os.path.exists(p) {
            return p;
        }
    }
    return "";
}

"""Load SoftwarePrompt objects from agent5-result.json cache file."""
def load_software_prompts_from_cache(cache_path: str) -> list[SoftwarePrompt] {
    f: Any = open(cache_path, "r");
    content: str = f.read();
    f.close();
    data: Any = json.loads(content);
    prompts: list[SoftwarePrompt] = [];
    for entry in data {
        prompts.append(
            SoftwarePrompt(
                category_name=entry.get("category_name", ""),
                problem=entry.get("problem", ""),
                score=entry.get("score", 0),
                software_name=entry.get("software_name", ""),
                description=entry.get("description", ""),
                core_features=entry.get("core_features", []),
                tech_stack=entry.get("tech_stack", ""),
                prompt=entry.get("prompt", "")
            )
        );
    }
    return prompts;
}

"""Run the full pipeline: fetch software prompts from Agent 5 (or cache), then run market and revenue analysis per prompt."""
def run_business_analysis() -> list[BusinessProfile] {
    software_prompts: list[SoftwarePrompt] = [];

    cache_path: str = find_agent5_cache();
    if cache_path != "" {
        print(f"BusinessOrchestrator: Found cache at '{cache_path}'. Loading Agent 5 results...");
        software_prompts = load_software_prompts_from_cache(cache_path);
        print(f"BusinessOrchestrator: Loaded {len(software_prompts)} software prompts from cache.");
    } else {
        print("BusinessOrchestrator: No cache found. Running Agents 1-5...");
        problems: list[ProblemStatement] = run_problem_creation();
        print(
            f"BusinessOrchestrator: Received {len(
                problems
            )} problems. Generating software prompts..."
        );
        problems_json: str = serialize_problems(problems);
        software_prompts = generate_software_prompts(problems_json);
        print(
            f"BusinessOrchestrator: Got {len(
                software_prompts
            )} software prompts. Running business analysis..."
        );
    }

    profiles: list[BusinessProfile] = [];
    for sp in software_prompts {
        item: Any = sp;
        print(f"BusinessOrchestrator: Analyzing '{item.software_name}'...");

        software_json: str = serialize_software_prompt(sp);
        market: MarketAnalysis = analyze_market(software_json);
        market_json: str = serialize_market(market);
        revenue: RevenueModel = generate_revenue_model(software_json, market_json);

        m: Any = market;
        r: Any = revenue;

        profile: BusinessProfile = BusinessProfile(
            software_name=item.software_name,
            problem=item.problem,
            description=item.description,
            tam_topdown=m.tam_topdown,
            tam_bottomup=m.tam_bottomup,
            sam=m.sam,
            som=m.som,
            addressable_accounts=m.addressable_accounts,
            icp_segments=m.icp_segments,
            avg_acv=m.avg_acv,
            market_growth_rate=m.market_growth_rate,
            business_model_type=r.business_model_type,
            pricing_strategy=r.pricing_strategy,
            revenue_streams=r.revenue_streams,
            monthly_revenue_range=r.monthly_revenue_range
        );
        profiles.append(profile);
    }
    return profiles;
}

walker BusinessOrchestrator {
    can run with Root entry {
        print("BusinessOrchestrator: Starting business development analysis...");
        profiles: list[BusinessProfile] = run_business_analysis();
        report profiles;
        print(
            f"BusinessOrchestrator: Completed analysis for {len(profiles)} software ideas."
        );
    }
}

with entry {
    result: Any = root() spawn BusinessOrchestrator();
    profiles: list[BusinessProfile] = result.reports[0];
    output: list[dict[str, Any]] = [];
    for bp in profiles {
        item: Any = bp;
        output.append(
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
            }
        );
    }
    print("\n=== Agent 6 Output: Business Profiles ===");
    print(json.dumps(output, indent=2));
}
