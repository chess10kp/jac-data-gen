cl {
    def:pub Profile(user_id: int) -> JsxElement {
        return <article>
            {try {
                <ResolvedProfile id={user_id}/>
            } awaiting {
                <p>Loading profile…</p>
            }}
        </article>;
    }
}
