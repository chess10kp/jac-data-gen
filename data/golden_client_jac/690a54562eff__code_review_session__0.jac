# pages/dashboard/layout.jac
cl import from "@jac/runtime" { Outlet, Link }

cl {
    def:pub layout() -> JsxElement {
        return <div className="dashboard">
            <aside>
                <nav aria-label="Dashboard">
                    <Link to="/dashboard">Overview</Link>
                    <Link to="/dashboard/settings">Settings</Link>
                    <Link to="/dashboard/profile">Profile</Link>
                </nav>
            </aside>

            <main>
                <Outlet />
            </main>
        </div>;
    }
}
