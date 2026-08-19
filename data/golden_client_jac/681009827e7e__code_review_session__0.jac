cl import from "@jac/runtime" { jacIsLoggedIn, jacLogin, jacLogout }

cl {
    import from react { createContext, useContext }

    glob AuthContext = createContext(None);

    # Auth Provider component -- `children` holds the nested JSX
    def:pub AuthProvider(children: any = None) -> JsxElement {
        has user: any = None;
        has loading: bool = True;

        can with entry {
            # Check auth status on mount
            if jacIsLoggedIn() {
                # Optionally fetch user data from backend
                user = {"authenticated": True};
            }
            loading = False;
        }

        async def login(username: str, password: str) -> bool {
            success = await jacLogin(username, password);
            if success {
                user = {"authenticated": True};
            }
            return success;
        }

        def logout() -> None {
            jacLogout();
            user = None;
        }

        value = {
            "user": user,
            "loading": loading,
            "isAuthenticated": user != None,
            "login": login,
            "logout": logout
        };

        return <AuthContext.Provider value={value}>
            {children}
        </AuthContext.Provider>;
    }

    def useAuth() -> dict {
        ctx = useContext(AuthContext);
        if ctx is None {
            raise ValueError("useAuth() must be called inside an <AuthProvider>");
        }
        return ctx;
    }
}
