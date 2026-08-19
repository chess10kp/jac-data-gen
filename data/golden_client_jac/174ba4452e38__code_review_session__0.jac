cl {
    def:pub UserPanel(user: User) -> JsxElement {
        return <section class="panel">
            {try {
                <UserCardView user={user}/>
            } awaiting {
                <UserCardSkeleton/>
            } except Exception as e {
                <div class="card error">Couldn't load this user: {e}</div>
            }}
        </section>;
    }
}
