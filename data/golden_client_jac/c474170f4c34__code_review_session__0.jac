cl import from "@jac/runtime" { Router, Routes, Route, Link, Outlet, useParams, useNavigate }

cl {
    def:pub Layout() -> JsxElement {
        return <div className="app">
            <header>
                <nav>
                    <Link to="/">Home</Link>
                    <Link to="/products">Products</Link>
                    <Link to="/about">About</Link>
                </nav>
            </header>

            <main>
                <Outlet />
            </main>

            <footer>
                <p>2024 My App</p>
            </footer>
        </div>;
    }

    def:pub Home() -> JsxElement {
        return <div>
            <h1>Welcome!</h1>
            <Link to="/products">Browse Products</Link>
        </div>;
    }

    def:pub Products() -> JsxElement {
        products = [
            {"id": 1, "name": "Widget A"},
            {"id": 2, "name": "Widget B"},
            {"id": 3, "name": "Widget C"}
        ];

        return <div>
            <h1>Products</h1>
            <ul>
                {[
                    <li key={p["id"]}>
                        <Link to={f"/products/{p['id']}"}>
                            {p["name"]}
                        </Link>
                    </li>
                    for p in products
                ]}
            </ul>
        </div>;
    }

    def:pub ProductDetail() -> JsxElement {
        params = useParams();
        navigate = useNavigate();

        product_id = params.get("id", "");

        if not product_id {
            return <div>
                <h1>Product not found</h1>
                <Link to="/products">All Products</Link>
            </div>;
        }

        return <div>
            <button onClick={lambda -> None { navigate(-1); }}>
                Back
            </button>
            <h1>Product {product_id}</h1>
            <p>Details about product {product_id}</p>
        </div>;
    }

    def:pub About() -> JsxElement {
        return <div>
            <h1>About Us</h1>
            <p>We make great products.</p>
        </div>;
    }

    def:pub NotFound() -> JsxElement {
        return <div>
            <h1>404 - Not Found</h1>
            <Link to="/">Go Home</Link>
        </div>;
    }

    def:pub app() -> JsxElement {
        return <Router>
            <Routes>
                <Route path="/" element={<Layout />}>
                    <Route index element={<Home />} />
                    <Route path="products" element={<Products />} />
                    <Route path="products/:id" element={<ProductDetail />} />
                    <Route path="about" element={<About />} />
                    <Route path="*" element={<NotFound />} />
                </Route>
            </Routes>
        </Router>;
    }
}
