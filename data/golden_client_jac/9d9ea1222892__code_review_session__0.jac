cl import from "@jac/runtime" { jacLogout }

cl {
    async def handleLogout() -> None {
        # Wait for logout to complete before navigating away
        await jacLogout();
        # User is now logged out
        navigate("/login");
    }
}
