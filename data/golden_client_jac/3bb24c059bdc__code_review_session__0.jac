cl import from "@jac/runtime" { JacClientErrorBoundary }

cl {
    def:pub Profile(user_id: int) -> JsxElement {
        return <article>
            <JacClientErrorBoundary fallback={<p>Could not load profile.</p>}>
                {try {
                    <ResolvedProfile id={user_id}/>
                } awaiting {
                    <p>Loading profile…</p>
                }}
            </JacClientErrorBoundary>
        </article>;
    }
}
