cl {
    def:pub UserPanel(user: User) -> JsxElement {
        return <section class="panel">
            {try {
                <UserCardView user={user}/>
            } awaiting {
                <UserCardSkeleton/>
            } except Exception {
                <div class="card error">Couldn't load this user.</div>
            }}
        </section>;
    }
}
