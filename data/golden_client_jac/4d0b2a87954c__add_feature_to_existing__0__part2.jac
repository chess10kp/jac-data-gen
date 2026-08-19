import asyncio;

async def get_items(n: int) -> list[int] {
    await asyncio.sleep(0.0);
    return [i for i in range(n)];
}

# Jac's type checker does not support `async for`, so we await the
# full batch and iterate normally, adding a min_value filter.
async def process_stream(n: int, min_value: int) -> None {
    items = await get_items(n);
    for item in items {
        if item >= min_value {
            print(item);
        }
    }
}

with entry {
    asyncio.run(process_stream(5, 2));
}
