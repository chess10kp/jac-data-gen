cl {
    def:pub MyComponent() -> JsxElement {
        name = "World";
        items = [1, 2, 3];

        return <div>
            <p>Hello, {name}!</p>
            <p>Sum: {sum(items)}</p>
            <p>Items: {len(items)}</p>
        </div>;
    }
}
