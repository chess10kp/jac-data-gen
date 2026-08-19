import from http { HTTPMethod }

glob APP_VERSION: str = "1.0.0";

@restspec(method=HTTPMethod.GET)
def :pub health_check() -> dict[str, str] {
    return {"status": "healthy"};
}

@restspec(method=HTTPMethod.GET, path="/custom/status")
def :pub app_status() -> dict[str, str] {
    return {"status": "running", "version": APP_VERSION};
}
