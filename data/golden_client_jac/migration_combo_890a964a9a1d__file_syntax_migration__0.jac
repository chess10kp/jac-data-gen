cl {
    def make(props: dict) -> JsxElement {
        return <div {**props}>hi</div>;
    }
}

with entry:__main__ {
    print("built");
}

import from os { path }

with entry {
    print(path.join("a", "b"));
}
