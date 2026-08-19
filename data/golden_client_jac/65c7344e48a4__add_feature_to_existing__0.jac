def search(query: str) -> str { return query; }
def fetch(url: str) -> str { return url; }
def analyze(data: str) -> str { return data; }
def summarize(text: str) -> str { return text; }

def my_agent(query: str) -> str by llm(
    tools=[search, fetch, analyze, summarize],
    parallelize=True
);
