"""Agent 2: Data Gathering Agent - Groups news articles from Agent 1 into categories."""

import from byllm.lib { Model }
import from typing { Any }
import json;
import from agent1_lookout { Trend, get_top_trends }
import from env_loader { OPENAI_API_KEY }

glob llm = Model(model_name="gpt-4o-mini", api_key=OPENAI_API_KEY);

"""A single news article with title and description."""
obj ArticleItem {
    has title: str = "";
    has description: str = "";
}

"""A group of related news articles under a common category."""
obj NewsCategory {
    has category_name: str = "";
    has summary: str = "";
    has articles: list[ArticleItem] = [];
}

"""Group similar news articles into meaningful categories."""
def group_news_into_categories(articles: list[ArticleItem]) -> list[NewsCategory] by llm;

sem group_news_into_categories = """
You are a news editor. Given a list of news articles (each with a title and description),
group them into meaningful categories based on their topics and themes.
Rules:
- Create 3-6 categories that best represent the themes in the articles
- Each article must belong to exactly one category
- Give each category a clear, descriptive name (e.g. 'Artificial Intelligence', 'Space Exploration', 'Financial Markets')
- Write a brief summary describing what the category covers based on the articles within it
- Every article from the input list must appear in exactly one of the output categories
- Each category must have at least 1 article
""";

"""Regroup articles into categories, applying the reviewer's feedback to improve quality."""
def regroup_with_feedback(
    articles: list[ArticleItem], feedback: str
) -> list[NewsCategory] by llm;

sem regroup_with_feedback = """
You are a news editor. Regroup the provided articles into meaningful categories.
You have received feedback from a reviewer — apply it carefully to improve the groupings.
Rules:
- Create 3-6 categories that best represent the themes in the articles
- Each article must belong to exactly one category
- Give each category a clear, descriptive name
- Write a brief summary describing what the category covers
- Every article from the input list must appear in exactly one output category
- Each category must have at least 1 article
- Address all points raised in the reviewer feedback
""";

"""Fetch articles from Agent 1 and convert to ArticleItem list."""
def fetch_articles() -> list[ArticleItem] {
    raw_articles: list[Trend] = get_top_trends();
    articles: list[ArticleItem] = [];
    for t in raw_articles {
        articles.append(ArticleItem(title=t.title, description=t.description));
    }
    return articles;
}

walker DataGatheringAgent {
    can run with Root entry {
        print("DataGatheringAgent: Fetching articles from Agent 1...");
        raw_articles: list[Trend] = get_top_trends();
        print(
            f"DataGatheringAgent: Received {len(
                raw_articles
            )} articles. Grouping into categories..."
        );

        # Convert Trend objects to local ArticleItem for byllm schema compatibility
        articles: list[ArticleItem] = [];
        for t in raw_articles {
            articles.append(ArticleItem(title=t.title, description=t.description));
        }

        categories: list[NewsCategory] = group_news_into_categories(articles);
        report categories;
        print(f"DataGatheringAgent: Grouped into {len(categories)} categories.");
    }
}

with entry {
    result: Any = root() spawn DataGatheringAgent();
    raw_categories: list[NewsCategory] = result.reports[0];
    output: list[dict[str, Any]] = [];
    for cat in raw_categories {
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
    print("=== Agent 2 Output ===");
    print(json.dumps(output, indent=2));
}
