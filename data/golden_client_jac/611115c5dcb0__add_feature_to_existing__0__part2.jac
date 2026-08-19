import asyncio;

async def fetch_data(url: str) -> str {
    await asyncio.sleep(0.0);
    return f"data from {url}";
}

# New: fetch several urls and join the results
async def fetch_all(urls: list[str]) -> str {
    parts = [];
    for url in urls {
        parts.append(await fetch_data(url));
    }
    return " | ".join(parts);
}

with entry {
    result = asyncio.run(fetch_all(["a.com", "b.com"]));
    print(result);
}
