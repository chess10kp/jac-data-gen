import from react { useRef }

def:pub useDrag() -> any {
    isDraggingRef = useRef(False);
    rafRef = useRef(None);
    lastXRef = useRef(0);

    def onMouseMove(e: any) -> None {
        if not isDraggingRef.current { return; }
        lastXRef.current = e.clientX;

        # Batch DOM updates with RAF
        if rafRef.current { return; }
        rafRef.current = requestAnimationFrame(lambda {
            rafRef.current = None;
            applyPosition(lastXRef.current);
        });
    }

    return {"onMouseMove": onMouseMove};
}
