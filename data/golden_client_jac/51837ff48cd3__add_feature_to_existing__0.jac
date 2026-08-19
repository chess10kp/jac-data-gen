useEffect(lambda {
    async def load {
        set_tasks(await get_tasks());
        await get_shopping_list();
    }
    load();
}, []);
