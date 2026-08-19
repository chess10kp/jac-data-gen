cl import from react { useState, useEffect }

cl def:pub app -> JsxElement {
    (tasks, set_tasks) = useState([]);
    (items, set_items) = useState([]);

    useEffect(lambda {
        async def load {
            set_tasks(await get_tasks());
        }
        load();
    }, []);

    # New: a second effect that loads the shopping list independently
    useEffect(lambda {
        async def load_items {
            set_items(await get_shopping_list());
        }
        load_items();
    }, []);

    return <div class="container">{len(tasks)} task(s), {len(items)} item(s)</div>;
}
