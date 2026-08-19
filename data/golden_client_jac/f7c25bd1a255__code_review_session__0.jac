cl {
    def:pub ConditionalComponent() -> JsxElement {
        has show: bool = False;
        has items: list = [];

        return <div>
            {(<p>Visible</p>) if show else (<p>Hidden</p>)}

            {[<li key={item["id"]}>{item["name"]}</li> for item in items]}
        </div>;
    }
}
