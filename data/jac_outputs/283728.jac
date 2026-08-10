"""speak"""
def speak(text: str) -> str {
    def whisper(t: str) -> str {
        t.lower() + '...'
    }
    return whisper(text);
}