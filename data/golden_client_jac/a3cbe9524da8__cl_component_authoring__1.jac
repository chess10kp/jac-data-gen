# hooks/usePolling.cl.jac
import from react { useRef, useEffect }

def:pub usePolling(callback: any, intervalMs: int, enabled: bool) -> None {
    timerRef = useRef(None);
    callbackRef = useRef(callback);
    callbackRef.current = callback;

    useEffect(lambda -> None {
        if not enabled { return lambda -> None {}; }

        def tick() -> None {
            callbackRef.current.call(None);
            timerRef.current = setTimeout(tick, intervalMs);
        }
        tick();

        return lambda -> None {
            if timerRef.current {
                clearTimeout(timerRef.current);
            }
        };
    }, [intervalMs, enabled]);
}
