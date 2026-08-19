# big_component.cl.jac
def:pub BigComponent -> JsxElement {
    has tasks: list[Task] = [];

    async def fetchTasks;        # signature only
    async def addTask;
    # ... render tree ...
}
