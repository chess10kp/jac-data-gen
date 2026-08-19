cl import from "@jac/runtime" { jacLogin }

cl {
    async def handleLogin() -> None {
        error = "";
        try {
            # jacLogin returns bool (True = success, False = failure)
            success = await jacLogin(username, password);
            if success {
                # User is now logged in, token stored automatically
                navigate("/dashboard");
            } else {
                error = "Invalid credentials";
            }
        } except Exception as ex {
            error = "Login request failed, please try again";
        }
    }
}
