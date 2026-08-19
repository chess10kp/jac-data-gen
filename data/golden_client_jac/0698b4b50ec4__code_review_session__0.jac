import asyncio;

walker async_processor {
    has items: list[object];

    async can process with Root entry {
        # Kick off every item at once; gather preserves input order.
        tasks = [process_item(item) for item in self.items];
        results = await asyncio.gather(*tasks);
        report list(results);
    }
}
