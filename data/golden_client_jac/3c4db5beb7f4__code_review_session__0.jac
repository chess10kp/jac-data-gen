def buildWsUrl(basePath: str, token: str) -> str {
    wsUrl = new(URL, String(window.location.origin));
    wsUrl.protocol = ("wss:" if window.location.protocol == "https:" else "ws:");
    wsUrl.pathname = basePath;
    wsUrl.search = "?token=" + encodeURIComponent(token);
    return str(wsUrl);
}
