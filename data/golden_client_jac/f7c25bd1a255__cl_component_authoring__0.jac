cl {
    def:pub ConditionalComponent() -> JsxElement {
        has show: bool = False;
        has items: list = [];

        if show {
            content = <p>Visible</p>;
        } else {
            content = <p>Hidden</p>;
        }
        return <div>
            {content}

            {show and <p>Only when true</p>}

            {[<li key={item["id"]}>{item["name"]}</li> for item in items]}
        </div>;
    }
}
