glob _errorCount: int = 0;
glob _maxRetries: int = 10;

def handleError(context: str, err: any) -> None {
    _errorCount = _errorCount + 1;
    console.error(f"[{context}] Error #{_errorCount}:", err);

    if _errorCount >= _maxRetries {
        console.warn(f"[{context}] Max retries reached, stopping.");
        return;
    }

    # Retry with backoff
    delay = 500 * _errorCount;
    setTimeout(lambda { retry(); }, delay);
}
