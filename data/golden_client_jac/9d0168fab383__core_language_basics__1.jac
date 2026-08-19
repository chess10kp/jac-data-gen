cl {
    def:pub FocusableInput() -> JsxElement {
        has inputRef: Ref[HTMLInputElement] = Ref();  # -> const inputRef = useRef(null)

        def focus() -> None {
            if inputRef.current { inputRef.current.focus(); }
        }

        return <div>
            <input ref={inputRef} type="text" />
            <button onClick={lambda -> None { focus(); }}>Focus</button>
        </div>;
    }
}
