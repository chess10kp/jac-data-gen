cl def:pub app -> JsxElement {
    return
        <div class="container">
            <h1>AI Day Planner</h1>
            <div class="two-column">
                <TasksColumn/>
                <ShoppingColumn/>
            </div>
        </div>;
}
