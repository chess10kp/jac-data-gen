cl {
    def:pub UserCardSkeleton() -> JsxElement {
        return <div class="card skeleton"><p>Loading user…</p></div>;
    }

    def:pub UserCardView(user: User) -> JsxElement {
        return <div class="card"><h2>{user.name}</h2><p>{user.bio}</p></div>;
    }

    def:pub UserPanel(user: User) -> JsxElement {
        return <section class="panel">
            {try {
                <UserCardView user={user}/>
            } awaiting {
                <UserCardSkeleton/>
            }}
        </section>;
    }
}
