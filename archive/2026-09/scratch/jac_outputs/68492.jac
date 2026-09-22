"""Event fixture."""
def event() -> object {
    return {
        "path": "/",
        "httpMethod": "GET",
        "headers": {"Host": "test.apigw.com"},
        "queryStringParameters": {}
    };
}