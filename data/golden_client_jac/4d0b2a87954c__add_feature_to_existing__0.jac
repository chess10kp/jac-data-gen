async def process_stream(stream: AsyncIterator, min_value: int) -> None {
    async for item in stream {
        if item >= min_value { print(item); }
    }
}
