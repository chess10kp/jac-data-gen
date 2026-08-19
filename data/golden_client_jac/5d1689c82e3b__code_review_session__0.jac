cl {
    import from react { createContext, useContext }

    glob AppContext = createContext(None);

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

    def:pub UserDisplay() -> JsxElement {
        ctx: any = useContext(AppContext);

        if ctx and ctx.user {
            return <p>Welcome, {ctx.user.name}!</p>;
        }
        return <p>Not logged in</p>;
    }

    def:pub ThemeToggle() -> JsxElement {
        ctx: any = useContext(AppContext);

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
