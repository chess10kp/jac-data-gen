async def fetch_data(url: str) -> str {
    return f"Data from {url}";
}

with entry {
    result = asyncio.run(fetch_data("https://example.com"));
    print(result);
}
