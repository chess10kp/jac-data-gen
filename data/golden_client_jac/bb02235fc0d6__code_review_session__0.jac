cl {
    import from react { useEffect }

    def use_local_storage(key: str, initial_value: any) -> tuple {
        has value: any = initial_value;

        useEffect(lambda -> None {
            stored = localStorage.getItem(key);
            if stored {
                try {
                    value = JSON.parse(stored);
                } except Exception {
                    value = initial_value;
                }
            }
        }, []);

        useEffect(lambda -> None {
            localStorage.setItem(key, JSON.stringify(value));
        }, [value]);

        return (value, lambda v: any -> None { value = v; });
    }

    def:pub Settings() -> JsxElement {
        (theme, set_theme) = use_local_storage("theme", "light");
        return <div>
            <p>Current: {theme}</p>
            <button onClick={lambda -> None { set_theme("dark"); }}>Dark</button>
        </div>;
    }
}
