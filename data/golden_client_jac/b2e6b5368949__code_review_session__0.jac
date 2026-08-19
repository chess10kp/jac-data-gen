cl import from "@jac/runtime" { jacSignup }

cl {
    async def handleSignup() -> None {
        # jacSignup returns dict with success key
        result = await jacSignup(username, password);

        if result["success"] {
            # User registered and logged in
            navigate("/dashboard");
        } else {
            error = (result["error"] if ("error" in result) else "Signup failed");
        }
    }
}
