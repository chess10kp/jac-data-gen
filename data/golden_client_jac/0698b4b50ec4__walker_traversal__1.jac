walker async_processor {
    has items: list;

    async can process with Root entry {
        results = [];
        for item in self.items {
            result = await process_item(item);
            results.append(result);
        }
        report results;
    }
}
