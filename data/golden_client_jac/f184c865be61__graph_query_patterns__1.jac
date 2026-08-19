import from react { useRef, useCallback, useEffect }

def:pub SearchBox() -> JsxElement {
    has query: str = "";           # Jac sugar for useState
    has results: list = [];        # Jac sugar for useState
    inputRef = useRef(None);       # Direct React hook

    # Jac sugar for useEffect with dependency
    async can with [query] entry {
        if query {
            results = await search_api(query);
        }
    }

    # Direct React useEffect for DOM manipulation
    useEffect(lambda -> None {
        if inputRef.current {
            inputRef.current.focus();
        }
    }, []);

    return <div>
        <input
            ref={inputRef}
            value={query}
            onChange={lambda e: ChangeEvent { query = e.target.value; }}
        />
        <ul>{[<li key={r.id}>{r.title}</li> for r in results]}</ul>
    </div>;
}
