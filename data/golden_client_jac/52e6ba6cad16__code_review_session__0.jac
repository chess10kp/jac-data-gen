glob _errorCount: int = 0;
glob _maxRetries: int = 10;

# Call this after a successful operation so the retry budget is restored
def resetErrorCount() -> None {
    _errorCount = 0;
}

def handleError(context: str, err: any) -> None {
    _errorCount = _errorCount + 1;
    console.error(f"[{context}] Error #{_errorCount}:", err);

    if _errorCount >= _maxRetries {
        console.warn(f"[{context}] Max retries reached, stopping.");
        return;
    }

    # Linear backoff: 500ms, 1000ms, 1500ms, ...
    delay = 500 * _errorCount;
    setTimeout(lambda { retry(); }, delay);
}
