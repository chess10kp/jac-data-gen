"""Agent 4: Problem Creator - Derives one scored problem statement from each news category."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { OPENAI_API_KEY }
import from agent3_reviewer { run_full_review }
import from agent2_data_gathering { NewsCategory, ArticleItem }

glob llm = Model(model_name="gpt-4o-mini", api_key=OPENAI_API_KEY);

"""A problem statement derived from a news category, with a relevance score."""
obj ProblemStatement {
    has category_name: str = "";
    has problem: str = "";
    has score: int = 0;
    has reasoning: str = "";
}

"""Given news categories as JSON, derive one problem statement per category and score them."""
def generate_problems(categories_json: str) -> list[ProblemStatement] by llm;

sem generate_problems = """
You are a product strategist analyzing trending news to uncover real-world problems worth solving with software.
You will receive a JSON list of news categories, each containing a category_name, summary, and articles.

For EACH category:
1. Identify the single most impactful problem that the articles in that category collectively highlight
2. State the problem clearly and concisely as a problem statement (1-2 sentences)
3. Score the problem from 1-10 based on:
   - Urgency: how pressing is this problem right now?
   - Scale: how many people are affected?
   - Solvability: how feasible is a software solution?
4. Provide a brief reasoning for your score

Return exactly one ProblemStatement per category.
""";

"""Serialize categories list to JSON string for LLM input."""
def serialize_categories(categories: list[NewsCategory]) -> str {
    output: list[dict[str, Any]] = [];
    for cat in categories {
        item: Any = cat;
        articles_out: list[dict[str, str]] = [];
        for art in item.articles {
            a: Any = art;
            articles_out.append({"title": a.title, "description": a.description});
        }
        output.append(
            {
                "category_name": item.category_name,
                "summary": item.summary,
                "articles": articles_out
            }
        );
    }
    return json.dumps(output, indent=2);
}

"""Run the full review → problem generation pipeline and return scored problems."""
def run_problem_creation() -> list[ProblemStatement] {
    print("ProblemCreatorAgent: Getting approved categories from Agent 3...");
    categories: list[NewsCategory] = run_full_review();
    print(
        f"ProblemCreatorAgent: Received {len(
            categories
        )} categories. Generating problems..."
    );

    categories_json: str = serialize_categories(categories);
    problems: list[ProblemStatement] = generate_problems(categories_json);

    print(f"ProblemCreatorAgent: Generated {len(problems)} problem statements.");
    for p in problems {
        item: Any = p;
        print(f"  [{item.score}/10] {item.category_name}: {item.problem}");
    }
    return problems;
}

walker ProblemCreatorAgent {
    can run with Root entry {
        problems: list[ProblemStatement] = run_problem_creation();
        report problems;
    }
}

with entry {
    result: Any = root() spawn ProblemCreatorAgent();
    problems: list[ProblemStatement] = result.reports[0];
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
    print("\n=== Agent 4 Output: Problem Statements ===");
    print(json.dumps(output, indent=2));
}
