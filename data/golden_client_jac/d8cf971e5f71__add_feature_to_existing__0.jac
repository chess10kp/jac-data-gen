async def fetch_with_retry(url: str, retries: int) -> dict {
    for i in range(retries) {
        data = fetch_data(url);
        if data["status"] == 200 { return data; }
    }
}
