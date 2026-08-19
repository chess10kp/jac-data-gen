cl def:pub app -> JsxElement {
    has count: int = 0;
    return <div>
        Count: {count}
        <button onClick={lambda -> None { count = count + 1; }}>+1</button>
    </div>;
}
