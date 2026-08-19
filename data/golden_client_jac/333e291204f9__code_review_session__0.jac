cl {
    import from react { createContext, useContext }

    glob AppContext = createContext(None);

    def:pub AppProvider(children: any = None) -> JsxElement {
        has theme: str = "light";

        def toggle() -> None {
            theme = "dark" if theme == "light" else "light";
        }

        return <AppContext.Provider value={{"theme": theme, "toggle": toggle}}>
            {children}
        </AppContext.Provider>;
    }

    def:pub ThemedComponent() -> JsxElement {
        ctx = useContext(AppContext);
        return <div className={ctx["theme"]}>
            <button onClick={lambda -> None { ctx["toggle"](); }}>Toggle</button>
            Content
        </div>;
    }
}
