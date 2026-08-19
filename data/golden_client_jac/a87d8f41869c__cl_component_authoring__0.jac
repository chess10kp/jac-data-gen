def:pub BookCard(bookId: str, title: str, onDelete: Callable[([str], None)]) -> JsxElement {
    def handle_delete(e: MouseEvent) {
        onDelete(bookId);
    }
    return <div>{title} <button onClick={handle_delete}>X</button></div>;
}
