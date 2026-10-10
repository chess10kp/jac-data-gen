"""Agent 3: Reviewer Agent - Reviews Agent 2 groupings, loops back with feedback or approves for Agent 4."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from env_loader { OPENAI_API_KEY }
import from agent2_data_gathering {
    ArticleItem,
    NewsCategory,
    group_news_into_categories,
    regroup_with_feedback,
    fetch_articles
}

glob llm = Model(model_name="gpt-4o-mini", api_key=OPENAI_API_KEY);

glob MAX_REVIEW_ITERATIONS: int = 3;

"""The result of a grouping review."""
obj ReviewDecision {
    has approved: bool = False;
    has feedback: str = "";
    has justification: str = "";
}

"""Review a set of news category groupings (provided as JSON string) for quality and correctness."""
def review_grouping(categories_json: str) -> ReviewDecision by llm;

sem review_grouping = """
You are a strict quality reviewer for news categorization.
The categories_json parameter contains a JSON array of grouped news categories, each with:
  - category_name: the name of the category
  - summary: a description of the category
  - articles: list of articles with title and description

Assess the grouping on:
1. Are the category names meaningful and distinct from each other?
2. Are all articles correctly placed — do they actually belong to their assigned category?
3. Is there any obvious misclassification or article that belongs elsewhere?
4. Are the categories too broad (mixing unrelated topics) or too narrow (unnecessary splits)?
5. Does each category summary accurately reflect its articles?

Set approved=True only if the grouping is high quality with no significant issues.
Set approved=False and provide specific, actionable feedback describing exactly what to fix.
Be strict but fair.
""";

"""Serialize categories to JSON string for the reviewer."""
def serialize_categories(categories: list[NewsCategory]) -> str {
    output: list[dict[str, Any]] = [];
    for cat in categories {
        articles_out: list[dict[str, str]] = [];
        for art in cat.articles {
            articles_out.append({"title": art.title, "description": art.description});
        }
        output.append(
            {
                "category_name": cat.category_name,
                "summary": cat.summary,
                "articles": articles_out
            }
        );
    }
    return json.dumps(output, indent=2);
}

"""Run the full fetch → group → review loop and return the final categories."""
def run_full_review() -> list[NewsCategory] {
    print("ReviewerAgent: Starting review loop...");

    articles: list[ArticleItem] = fetch_articles();
    categories: list[NewsCategory] = group_news_into_categories(articles);

    approved: bool = False;
    iteration: int = 0;

    while not approved and iteration < MAX_REVIEW_ITERATIONS {
        iteration += 1;
        print(f"ReviewerAgent: Review iteration {iteration}/{MAX_REVIEW_ITERATIONS}...");

        categories_json: str = serialize_categories(categories);
        decision: ReviewDecision = review_grouping(categories_json);

        if decision.approved {
            approved = True;
            print(f"ReviewerAgent: APPROVED on iteration {iteration}.");
            print(f"Justification: {decision.justification}");
        } else {
            print(f"ReviewerAgent: REJECTED on iteration {iteration}.");
            print(f"Feedback: {decision.feedback}");
            if iteration < MAX_REVIEW_ITERATIONS {
                print("ReviewerAgent: Sending feedback to Agent 2 for regrouping...");
                categories = regroup_with_feedback(articles, decision.feedback);
            }
        }
    }

    return categories;
}

walker ReviewerAgent {
    can run with Root entry {
        categories: list[NewsCategory] = run_full_review();
        report categories;
    }
}

with entry {
    result: Any = root() spawn ReviewerAgent();
    outcome: Any = result.reports[0];

    if isinstance(outcome, str) {
        print(f"\n=== Agent 3 Output ===\n{outcome}");
    } else {
        categories: list[NewsCategory] = outcome;
        output: list[dict[str, Any]] = [];
        for cat in categories {
            articles_out: list[dict[str, str]] = [];
            for art in cat.articles {
                articles_out.append(
                    {"title": art.title, "description": art.description}
                );
            }
            output.append(
                {
                    "category_name": cat.category_name,
                    "summary": cat.summary,
                    "articles": articles_out
                }
            );
        }
        print("\n=== Agent 3 Output: Approved Categories for Agent 4 ===");
        print(json.dumps(output, indent=2));
    }
}
