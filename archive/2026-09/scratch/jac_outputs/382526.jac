"""Asserts if sound file is valid."""
def is_sound_valid(wav_file: str) -> bool {
    wav_file.endswith(".wav")
}