cl {
    def:pub FocusableInput() -> JsxElement {
        has inputRef: Ref[HTMLInputElement] = Ref();

        return <div>
            <input ref={inputRef} type="text" />
            <button onClick={lambda -> None {
                if inputRef.current { inputRef.current.focus(); }
            }}>Focus</button>
        </div>;
    }
}
