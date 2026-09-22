"""JPEG data in JFIF or Exif format"""
def test_jpeg(h: bytes, f: bytes) -> str | None {
    if h[6:10] in (b'JFIF', b'Exif') {
        return 'jpeg';
    }
}