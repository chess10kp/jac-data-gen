"""Async operations in Jac."""
import asyncio;

async def fetch_data(url: str) -> str {
    # Simulate async fetch
    await asyncio.sleep(0.1);
    return f"Data from {url}";
}

with entry {
    result = asyncio.run(fetch_data("https://example.com"));
    print(result);
}
