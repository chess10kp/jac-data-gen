import from react { createContext, useContext, useState, useEffect }

glob _GRAPH_CTX_BOX: list = [];

def _graph_ctx() -> object {
    if len(_GRAPH_CTX_BOX) == 0 {
        _GRAPH_CTX_BOX.append(createContext(None));
    }
    return _GRAPH_CTX_BOX[0];
}

def:pub useGraphState() -> object {
    Ctx = _graph_ctx();
    return useContext(Ctx);
}

async def fetchGraphStateReport() -> object {
    res = await fetch( # jac:ignore[E1032]
        "/walker/GraphStateProxy",
        {"method": "POST", "headers": {"Content-Type": "application/json"}, "body": "{}"}
    );
    body = await res.json(); # jac:ignore[E1032]
    data = body["data"] if body and ("data" in body) else {};
    reps = data["reports"] if data and ("reports" in data) else [];
    return reps[0] if reps and len(reps) > 0 else None;
}

def:pub GraphStateProvider(children: any) -> JsxElement {
    Ctx = _graph_ctx();
    [`report, setReport] = useState(None);
    [loading, setLoading] = useState(True);
    [error, setError] = useState(None);

    useEffect(lambda () -> any {
        isMounted = True;

        async def runFetch() -> None {
            try {
                latest = await fetchGraphStateReport();
                if isMounted {
                    setReport(latest);
                    setError(None);
                }
            } except Exception as e { # jac:ignore[W2052]
                if isMounted {
                    setError(str(e) if str(e) else "unavailable");
                }
            }
            if isMounted {
                setLoading(False);
            }
        }

        runFetch();
        timer_id = setInterval(lambda () -> None { runFetch(); }, 5000); # jac:ignore[E1032]
        return lambda () -> None {
            isMounted = False;
            clearInterval(timer_id); # jac:ignore[E1032]
        };
    }, []);

    ctxVal = {"report": `report, "loading": loading, "error": error};
    return <Ctx.Provider value={ctxVal}>{children}</Ctx.Provider>;
}
