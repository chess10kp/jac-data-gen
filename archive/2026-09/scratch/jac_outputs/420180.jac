"""Build body of the add issue comment request"""
def make_comment_body(comment_text: Any) -> object {
    return {
        "body": {
            "type": "doc",
            "version": 1,
            "content": [
                {
                    "type": "paragraph",
                    "content": [{"text": comment_text, "type": "text"}]
                }
            ]
        }
    };
}