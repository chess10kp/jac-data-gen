cl import from "@jac/runtime" { useParams }

cl {
    def:pub BlogPost() -> JsxElement {
        params = useParams();
        category = params.get("category", "");
        postId = params.get("postId", "");

        return <div>
            <p>Category: {category}</p>
            <p>Post ID: {postId}</p>
        </div>;
    }
}
