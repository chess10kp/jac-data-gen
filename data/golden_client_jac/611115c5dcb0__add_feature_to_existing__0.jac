async def fetch_all(urls: list[str]) -> str {
    parts = [fetch_data(u) for u in urls];
    return " | ".join(parts);
}
