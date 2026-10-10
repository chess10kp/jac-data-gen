"""
Idea-to-Prototype Generator - JacHacks 2026
Multi-agent Jac backend using jaclang + MTLLM (Groq)
"""

import:py from mtllm.llms, Groq;
import:py json;

glob llm = Groq(model="llama-3.3-70b-versatile");

# ─── Node ─────────────────────────────────────────────────────────────────────

node IdeaNode {
    has raw_idea: str;
    has prd: dict = {};
    has planned: dict = {};
    has architecture: dict = {};
    has starter_code: dict = {};
}

# ─── Agent Functions (MTLLM "by llm" semantic functions) ─────────────────────

"""You are Scout, a senior product thinking AI.
Convert the raw_idea into a structured Product Requirements Document.
Return ONLY valid JSON with exactly these keys:
  problem    : string — one clear problem statement
  users      : list of 2 user-persona strings
  features   : list of 5 dicts, each {name: str, description: str}
  constraints: list of 3-4 constraint strings
No markdown fences, no extra text — raw JSON only."""
func refine_idea(raw_idea: str) -> dict by llm(temperature=0.7);

"""You are Planner, a product manager AI running a 24-hour hackathon sprint.
Given the PRD dict, produce a concise execution plan.
Return ONLY valid JSON with exactly these keys:
  title      : string — creative, catchy product name (1-3 words)
  tagline    : string — one-sentence value proposition
  milestones : list of 3 dicts, each {name, description, estimated_time}
No markdown fences, no extra text — raw JSON only."""
func generate_plan(prd: dict) -> dict by llm(temperature=0.7);

"""You are Architect, an experienced software architect AI.
Given the product plan dict, design the technical architecture.
Return ONLY valid JSON with exactly these keys:
  tech_stack       : dict with keys: backend, frontend, database, ai_model, deployment
  folder_structure : string — full ASCII project tree (use └── ├── │ characters)
  data_flow        : string — 3-4 sentences describing user→system→AI→response flow
  api_endpoints    : list of 4-5 dicts, each {method, path, description}
No markdown fences, no extra text — raw JSON only."""
func design_architecture(planned: dict) -> dict by llm(temperature=0.5);

"""You are Code Agent, an expert full-stack developer AI.
Generate minimal but runnable starter code for this project.
Return ONLY valid JSON where:
  - keys   = file paths (e.g. "server/main.py", "client/index.html")
  - values = complete file content as strings
Generate exactly these 7 files:
  1. server/main.py        — FastAPI backend with 3 routes stubbed, CORS enabled
  2. server/models.py      — Pydantic models matching the PRD domain
  3. client/index.html     — clean HTML with Tailwind CSS CDN, dark UI
  4. client/app.js         — vanilla JS for API calls and UI updates
  5. ai/agent.py           — Groq AI logic stub using llama-3.3-70b-versatile
  6. requirements.txt      — all Python deps (fastapi, uvicorn, groq, pydantic, etc.)
  7. README.md             — setup instructions (max 20 lines)
Keep code clean, minimal, commented.
No markdown fences around the JSON — raw JSON only."""
func generate_starter_code(arch: dict, prd: dict) -> dict by llm(temperature=0.4);

# ─── Walker ───────────────────────────────────────────────────────────────────

walker build_idea_to_prototype {
    has raw_input: str;

    can run with IdeaNode entry {
        here.raw_idea = raw_input;

        # Agent 1 — Scout
        here.prd = refine_idea(here.raw_idea);

        # Agent 2 — Planner
        here.planned = generate_plan(here.prd);

        # Agent 3 — Architect
        here.architecture = design_architecture(here.planned);

        # Agent 4 — Code Agent
        here.starter_code = generate_starter_code(here.architecture, here.prd);

        report {
            "title"       : here.planned.get("title", "My Project"),
            "tagline"     : here.planned.get("tagline", ""),
            "prd"         : here.prd,
            "planned"     : here.planned,
            "architecture": here.architecture,
            "files"       : here.starter_code
        };
    }
}

# ─── Entry Point (standalone run) ─────────────────────────────────────────────

with entry {
    idea_node = spawn IdeaNode(raw_idea="");
    w = build_idea_to_prototype(raw_input="Habit tracker for high school students");
    result = w spawn idea_node;
    print(json.dumps(result, indent=2));
}
