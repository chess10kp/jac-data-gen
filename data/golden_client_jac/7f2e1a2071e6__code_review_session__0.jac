# pages/posts/[slug].jac
cl import from "@jac/runtime" { Link, useParams }

cl {
    def:pub page() -> JsxElement {
        params = useParams();
        slug = params.get("slug", "");

        if not slug {
            return <article>
                <Link to="/posts">All Posts</Link>
                <h1>Post not found</h1>
            </article>;
        }

        return <article>
            <Link to="/posts">All Posts</Link>
            <h1>Blog Post</h1>
            <p>Slug: {slug}</p>
        </article>;
    }
}
