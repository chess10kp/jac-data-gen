cl {
    import from react { createContext, useContext }

    # Create context
    glob AppContext = createContext(None);

    # Provider component -- `children` is the nested JSX passed between its tags
    def:pub AppProvider(children: any = None) -> JsxElement {
        has user: any = None;
        has theme: str = "light";

        value = {
            "user": user,
            "theme": theme,
            "setUser": lambda u: any -> None { user = u; },
            "setTheme": lambda t: str -> None { theme = t; }
        };

        return <AppContext.Provider value={value}>
            {children}
        </AppContext.Provider>;
    }

    # Consumer component
    def:pub UserDisplay() -> JsxElement {
        ctx = useContext(AppContext);

        if ctx.user {
            return <p>Welcome, {ctx.user.name}!</p>;
        }
        return <p>Not logged in</p>;
    }

    def:pub ThemeToggle() -> JsxElement {
        ctx = useContext(AppContext);

        return <button onClick={lambda -> None {
            ctx.setTheme("dark" if ctx.theme == "light" else "light");
        }}>
            Toggle Theme ({ctx.theme})
        </button>;
    }

    def:pub app() -> JsxElement {
        return <AppProvider>
            <UserDisplay />
            <ThemeToggle />
        </AppProvider>;
    }
}
