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
    if msg and msg.id != undefined and _pendingCallbacks[String(msg.id)] {
        cb = _pendingCallbacks[String(msg.id)];
        _pendingCallbacks[String(msg.id)] = undefined;
        cb.call(None, msg);
    }
}
