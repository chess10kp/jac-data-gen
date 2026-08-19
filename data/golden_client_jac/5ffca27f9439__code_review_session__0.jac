glob _nextReqId: int = 1;
glob _pendingCallbacks: any = {};

def wsRequest(method: str, params: any, callback: any) -> None {
    reqId = _nextReqId;
    _nextReqId = _nextReqId + 1;

    msg = {
        "id": reqId,
        "method": method,
        "params": params
    };

    _pendingCallbacks[String(reqId)] = callback;
    _ws.send(JSON.stringify(msg));
}

def handleResponse(msg: any) -> None {
    key = String(msg.id);
    if msg and msg.id != undefined and _pendingCallbacks[key] {
        cb = _pendingCallbacks[key];
        del _pendingCallbacks[key];  # remove entry so the map doesn't grow unbounded
        cb.call(None, msg);
    }
}
