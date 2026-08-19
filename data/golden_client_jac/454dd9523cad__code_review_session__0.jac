cl import from "@jac/runtime" { Link, useLocation }

cl {
    def:pub Navigation() -> JsxElement {
        location = useLocation();

        def isActive(path: str) -> bool {
            return location.pathname == path;
        }

        return <nav>
            <Link
                to="/"
                aria-current={"page" if isActive("/") else None}
                className={"nav-link " + ("active" if isActive("/") else "")}
            >
                Home
            </Link>

            <Link
                to="/about"
                aria-current={"page" if isActive("/about") else None}
                className={"nav-link " + ("active" if isActive("/about") else "")}
            >
                About
            </Link>
        </nav>;
    }
}
