cl {
    async def fetch_data() -> list { return []; }

    def:pub DataLoader() -> JsxElement {
        has data: list = [];
        has loading: bool = True;

        async can with entry {
            data = await fetch_data();
            loading = False;
        }

        return <div>...</div>;
    }
}
