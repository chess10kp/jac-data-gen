cl import from "@jac/runtime" { Router, Routes, Route, Outlet, Link }

cl {
    def:pub DashboardLayout() -> JsxElement {
        return <div className="dashboard">
            <aside>
                <Link to="/dashboard">Overview</Link>
                <Link to="/dashboard/settings">Settings</Link>
                <Link to="/dashboard/profile">Profile</Link>
            </aside>

            <main>
                <Outlet />
            </main>
        </div>;
    }

    def:pub DashboardHome() -> JsxElement {
        return <h2>Dashboard Overview</h2>;
    }

    def:pub DashboardSettings() -> JsxElement {
        return <h2>Settings</h2>;
    }

    def:pub DashboardProfile() -> JsxElement {
        return <h2>Profile</h2>;
    }

    def:pub DashboardNotFound() -> JsxElement {
        return <h2>Section not found</h2>;
    }

    def:pub app() -> JsxElement {
        return <Router>
            <Routes>
                <Route path="/dashboard" element={<DashboardLayout />}>
                    <Route index element={<DashboardHome />} />
                    <Route path="settings" element={<DashboardSettings />} />
                    <Route path="profile" element={<DashboardProfile />} />
                    <Route path="*" element={<DashboardNotFound />} />
                </Route>
            </Routes>
        </Router>;
    }
}
