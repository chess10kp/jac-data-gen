cl {
    async def fetch_data() -> list { return []; }
    def cleanup_subscriptions() -> None {}
    async def fetch_user(userId: str) -> dict { return {}; }

    def:pub DataLoader() -> JsxElement {
        has data: list = [];
        has loading: bool = True;
        async can with entry {
            data = await fetch_data();
            loading = False;
        }
        can with exit { cleanup_subscriptions(); }
        return <div>...</div>;
    }

    def:pub UserProfile(userId: str) -> JsxElement {
        has user: dict = {};
        async can with [userId] entry {
            user = await fetch_user(userId);
        }
        return <div>{user["name"]}</div>;
    }
}
