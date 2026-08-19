async walker DataFetcher {
    has url: str;

    async can fetch with Root entry {
        data = await http_get(self.url);
        report data;
    }
}
