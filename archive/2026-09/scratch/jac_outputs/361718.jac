"""rescale image to 300dpi"""
def crop_resize(src: str, target: str, right: int = 0, bottom: int = 70) -> list[str] {
    cropargs = '-{}-{}'.format(right, bottom);
    return ['convert', src, '-crop', cropargs, '-resize', '150%', target];
}