"""Agent 1: Lookout Agent - Fetches and identifies current market trends from news."""

import from byllm.lib { Model }
import from typing { Any }
import requests;
import json;
import from env_loader { OPENAI_API_KEY, NEWS_API_KEY }

glob llm = Model(model_name="gpt-4o-mini", api_key=OPENAI_API_KEY);

"""Represents a single article/trend with title and description."""
obj Trend {
    has title: str = "";
    has description: str = "";
}

"""Fetch top headlines from News API for a given category."""
def fetch_top_headlines(
    category: str = "technology", country: str = "us", page_size: int = 20
) -> list[dict[str, str]] {
    url: str = "https://newsapi.org/v2/top-headlines";
    params: dict[str, str] = {
        "apiKey": NEWS_API_KEY,
        "category": category,
        "country": country,
        "pageSize": str(page_size)
    };
    resp: Any = requests.get(url, params=params);
    data: Any = resp.json();
    articles: list[dict[str, str]] = [];
    if data.get("status") == "ok" {
        for article in data.get("articles", []) {
            articles.append(
                {
                    "title": article.get("title", ""),
                    "description": article.get("description", ""),
                    "source": article.get("source", {}).get("name", ""),
                    "publishedAt": article.get("publishedAt", ""),
                    "url": article.get("url", "")
                }
            );
        }
    }
    print(f"Fetched articles from {category}");
    return articles;
}

"""Search for news articles about a specific topic or keyword."""
def search_news(query: str, page_size: int = 20) -> list[dict[str, str]] {
    url: str = "https://newsapi.org/v2/everything";
    params: dict[str, str] = {
        "apiKey": NEWS_API_KEY,
        "q": query,
        "pageSize": str(page_size),
        "sortBy": "publishedAt",
        "language": "en"
    };
    resp: Any = requests.get(url, params=params);
    data: Any = resp.json();
    articles: list[dict[str, str]] = [];
    if data.get("status") == "ok" {
        for article in data.get("articles", []) {
            articles.append(
                {
                    "title": article.get("title", ""),
                    "description": article.get("description", ""),
                    "source": article.get("source", {}).get("name", ""),
                    "publishedAt": article.get("publishedAt", ""),
                    "url": article.get("url", "")
                }
            );
        }
    }
    return articles;
}

"""Extract top 10 articles from multiple categories."""
def get_top_trends() -> list[Trend] {
    trends: list[Trend] = [];
    categories: list[str] = ["technology", "business", "science"];

    for category in categories {
        articles: list[dict[str, str]] = fetch_top_headlines(
            category=category, page_size=5
        );
        for article in articles {
            if len(trends) < 10 {
                trends.append(
                    Trend(
                        title=article.get("title", ""),
                        description=article.get("description", "")
                    )
                );
            }
        }
    }
    return trends;
}

walker LookoutAgent {
    can run with Root entry {
        print("LookoutAgent: Fetching top trends...");
        trends: list[Trend] = get_top_trends();
        report trends;
        print(f"LookoutAgent: Fetched {len(trends)} trends.");
    }
}

with entry {
    result: Any = root() spawn LookoutAgent();
    raw_trends: list[Trend] = result.reports[0];
    output: list[dict[str, Any]] = [];
    for t in raw_trends {
        output.append({"title": t.title, "description": t.description});
    }
    print(json.dumps(output, indent=2));
}
