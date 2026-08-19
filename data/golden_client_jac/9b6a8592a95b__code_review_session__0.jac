cl {
    def:pub Form() -> JsxElement {
        has name: str = "";
        has email: str = "";
        has submitted: bool = False;

        def handle_submit() -> None {
            print(f"Submitting: {name}, {email}");
            submitted = True;
        }

        if submitted {
            return <p>Thanks, {name}!</p>;
        }

        return <form onSubmit={lambda e: any { e.preventDefault(); handle_submit(); }}>
            <input
                value={name}
                onChange={lambda e: ChangeEvent { name = e.target.value; }}
                placeholder="Name"
            />
            <input
                value={email}
                onChange={lambda e: ChangeEvent { email = e.target.value; }}
                placeholder="Email"
            />
            <button type="submit">
                Submit
            </button>
        </form>;
    }
}
