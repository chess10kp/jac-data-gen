"""Agent 5: Software Prompt Generator - Creates a software development prompt for each problem."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { OPENAI_API_KEY }
import from agent4_problem_creator { run_problem_creation, ProblemStatement }

glob llm = Model(model_name="gpt-4o-mini", api_key=OPENAI_API_KEY);

"""A fully-formed software development prompt for a given problem."""
obj SoftwarePrompt {
    has category_name: str = "";
    has problem: str = "";
    has score: int = 0;
    has software_name: str = "";
    has description: str = "";
    has core_features: list[str] = [];
    has tech_stack: str = "";
    has prompt: str = "";
}

"""Given problem statements as JSON, generate a software development prompt for each."""
def generate_software_prompts(problems_json: str) -> list[SoftwarePrompt] by llm;

sem generate_software_prompts = """
You are a software architect and product designer. You will receive a JSON list of problem statements,
each with a category_name, problem, score, and reasoning.

For EACH problem, design a small, focused software application that directly addresses it:
  - software_name: a short, catchy app name
  - description: one paragraph describing what the app does and who it's for
  - core_features: a list of 3-5 key features the app must have (be specific)
  - tech_stack: recommended technologies (e.g., "Python backend, React frontend, REST API")
  - prompt: a complete, detailed prompt that a Jac language AI coder could use to build this software.
    The prompt should describe the full app: purpose, features, data model, and UI behavior.
    It should be self-contained — someone reading only the prompt should understand exactly what to build.

Return one SoftwarePrompt per problem.
""";

"""Serialize problem statements list to JSON string for LLM input."""
def serialize_problems(problems: list[ProblemStatement]) -> str {
    output: list[dict[str, Any]] = [];
    for p in problems {
        item: Any = p;
        output.append(
            {
                "category_name": item.category_name,
                "problem": item.problem,
                "score": item.score,
                "reasoning": item.reasoning
            }
        );
    }
    return json.dumps(output, indent=2);
}

walker SoftwarePromptAgent {
    can run with Root entry {
        print("SoftwarePromptAgent: Getting problem statements from Agent 4...");
        problems: list[ProblemStatement] = run_problem_creation();
        print(
            f"SoftwarePromptAgent: Received {len(
                problems
            )} problems. Generating software prompts..."
        );

        problems_json: str = serialize_problems(problems);
        software_prompts: list[SoftwarePrompt] = generate_software_prompts(
            problems_json
        );
        report software_prompts;

        print(
            f"SoftwarePromptAgent: Generated {len(software_prompts)} software prompts."
        );
    }
}

with entry {
    result: Any = root() spawn SoftwarePromptAgent();
    prompts: list[SoftwarePrompt] = result.reports[0];
    output: list[dict[str, Any]] = [];
    for sp in prompts {
        item: Any = sp;
        output.append(
            {
                "category_name": item.category_name,
                "problem": item.problem,
                "score": item.score,
                "software_name": item.software_name,
                "description": item.description,
                "core_features": item.core_features,
                "tech_stack": item.tech_stack,
                "prompt": item.prompt
            }
        );
    }
    print("\n=== Agent 5 Output: Software Prompts (Ready for Jac Coder) ===");
    print(json.dumps(output, indent=2));
}
