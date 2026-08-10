"""Given a midi pitch (e.g. 60 == C), returns its corresponding chroma class value."""
def midi_to_chroma(pitch: int) -> int {
    ((pitch % 12) + 3) % 12
}