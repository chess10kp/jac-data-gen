glob _ws: any = None;

def connectWebSocket(url: str) -> None {
    # Close any existing socket before opening a new one
    if _ws {
        _ws.close();
    }
    _ws = new(WebSocket, url);

    _ws.onopen = lambda {
        console.log("WebSocket connected");
    };

    _ws.onmessage = lambda(event: any) {
        try {
            msg = JSON.parse(event.data);
            handleMessage(msg);
        } except Exception as e {
            console.error("WS message error:", e);
        }
    };

    _ws.onerror = lambda(e: any) {
        console.warn("WS error:", e);
    };

    _ws.onclose = lambda {
        console.log("WebSocket closed, reconnecting in 2s...");
        setTimeout(lambda { connectWebSocket(url); }, 2000);
    };
}
