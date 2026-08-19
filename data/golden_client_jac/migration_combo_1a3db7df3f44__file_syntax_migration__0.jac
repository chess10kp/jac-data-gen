with entry {
    x = root;
    print(x);
}

cl {
    def make(props: dict) -> JsxElement {
        return <div {**props}>hi</div>;
    }
}

with entry:__main__ {
    print("built");
}
