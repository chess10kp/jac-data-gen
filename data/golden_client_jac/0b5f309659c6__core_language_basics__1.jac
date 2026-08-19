cl {
    def:pub JsxExamples() -> JsxElement {
        has variable: str = "text";
        has condition: bool = True;
        has items: list = [];
        has props: dict = {};

        return <div>
            <input type="text" value={variable} />

            {condition and <div>Shown if true</div>}

            {items}

            <button {**props} {variable}>Click</button>
        </div>;
    }
}
