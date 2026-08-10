"""Expect credentials to be passed in headers."""
def service_proxy_settings(service_proxy_settings: dict[str, str]) -> dict[str, str] {
    service_proxy_settings.update({"credentials_location": "headers"});
    return service_proxy_settings;
}