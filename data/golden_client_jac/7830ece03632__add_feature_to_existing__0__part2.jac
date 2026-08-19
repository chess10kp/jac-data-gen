async walker DataFetcher {
    has url: str;
    has retries: int = 1;

    async can fetch with `root entry {
        data = await get(self.url);
        report data;
    }

    # New ability: report the configured retry count on exit
    can summarize with exit {
        report {"url": self.url, "retries": self.retries};
    }
}

async def get(url: str) -> str {
    return f"payload:{url}";
}
