cl {
    import from react { createContext, useContext }

    glob AppContext = createContext(None);

    def:pub AppProvider(children: any = None) -> JsxElement {
        has theme: str = "light";

        return <AppContext.Provider value={{"theme": theme}}>
            {children}
        </AppContext.Provider>;
    }

    def:pub ThemedComponent() -> JsxElement {
        ctx = useContext(AppContext);
        return <div className={ctx.theme}>Content</div>;
    }
}
