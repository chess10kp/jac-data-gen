def sendMessage(action: str, data: any) -> bool {
    if not _ws or _ws.readyState != WebSocket.OPEN {
        console.warn("WebSocket not connected");
        return False;
    }

    msg = {
        "action": action,
        "data": data
    };

    try {
        _ws.send(JSON.stringify(msg));
        return True;
    } except Exception as e {
        console.warn("WS send failed:", e);
        return False;
    }
}
