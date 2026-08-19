import asyncio;

async def fetch_data(url: str) -> dict {
    await asyncio.sleep(0.0);
    return {"url": url, "status": 200};
}

async def process_multiple(urls: list[str]) -> list[dict] {
    results = [];
    for url in urls {
        data = await fetch_data(url);
        results.append(data);
    }
    return results;
}

# New: retry wrapper around fetch_data
async def fetch_with_retry(url: str, retries: int) -> dict {
    attempt = 0;
    while attempt < retries {
        data = await fetch_data(url);
        if data["status"] == 200 {
            return data;
        }
        attempt += 1;
    }
    return {"url": url, "status": 0};
}
