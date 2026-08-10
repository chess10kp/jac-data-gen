"""OpenCV supported image formats"""
def is_image(path: str) -> bool {
    extensions = [
        'bmp',
        'dib',
        'jpeg',
        'jpg',
        'jpe',
        'jp2',
        'png',
        'webp' 'pbm',
        'pgm',
        'ppm',
        'pxm',
        'pnm',
        'pfm',
        'sr',
        'ras',
        'tiff',
        'tif',
        'exr',
        'hdr',
        'pic'
    ];
    return any(path.lower().endswith('.' + ext) for ext in extensions);
}