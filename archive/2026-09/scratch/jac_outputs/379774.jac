"""
Convert YeT extension in filename to .tex
"""
def convert_extension(filename: str, extensions: tuple[str, ...] = ('yaml', 'yml')) -> str {
    if '.' in filename {
        ext = filename.split('.')[-1];
        if ext in extensions {
            idx = filename.rindex('.');
            return f'{filename[:idx]}.tex';
        }
    }
    return f'{filename}.tex';
}