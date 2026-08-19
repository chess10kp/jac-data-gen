cl import from "@jac/runtime" { Router, Routes, Route, useParams }

cl {
    def:pub Home() -> JsxElement {
        return <h1>Home</h1>;
    }

    def:pub UserProfile() -> JsxElement {
        params = useParams();
        userId = params["id"];

        return <div>
            <h1>User Profile</h1>
            <p>Viewing user: {userId}</p>
        </div>;
    }

    def:pub app() -> JsxElement {
        return <Router>
            <Routes>
                <Route path="/" element={<Home />} />
                <Route path="/user/:id" element={<UserProfile />} />
            </Routes>
        </Router>;
    }
}
