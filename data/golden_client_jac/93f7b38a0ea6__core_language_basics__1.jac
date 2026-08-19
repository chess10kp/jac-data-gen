def sendMessage(action: str, data: any) -> None {
    if not _ws or _ws.readyState != 1 {
        console.warn("WebSocket not connected");
        return;
    }

    msg = {
        "action": action,
        "data": data
    };

    try {
        _ws.send(JSON.stringify(msg));
    } except Exception as e {
        console.warn("WS send failed:", e);
    }
}
