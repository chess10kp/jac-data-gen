import from react { useRef }

def:pub useAutoSave() -> any {
    timerRef = useRef(None);

    def save(path: str, content: str) -> None {
        # Clear previous timer
        if timerRef.current {
            clearTimeout(timerRef.current);
        }
        # Set new 2-second debounce
        timerRef.current = setTimeout(lambda {
            timerRef.current = None;
            writeFile(path, content);
        }, 2000);
    }

    def flush() -> None {
        if timerRef.current {
            clearTimeout(timerRef.current);
            timerRef.current = None;
        }
    }

    return {"save": save, "flush": flush};
}
