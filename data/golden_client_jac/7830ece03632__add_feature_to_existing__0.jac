async walker DataFetcher {
    has retries: int = 1;
    can summarize with exit {
        report {"url": self.url, "retries": self.retries};
    }
}
