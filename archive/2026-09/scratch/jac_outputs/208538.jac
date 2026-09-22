"""
If a file can't be decoded by ascii or there are NULL ('\x00') bytes
assume this is a binary file.
"""
def is_binary_file(file_path: str, block_size: int = 512) -> bool {
    assert type(file_path) == str;
    try {
        with open(file_path, 'rb') as f {
            block = f.read(block_size);
            if b'\x00' in block {
                return True;
            } elif not block {
                return False;
            }
            try {
                block.decode('ascii');
                return False;
            } except UnicodeDecodeError {
                return True;
            }
        }
    } except IOError {
        return False;
    }
}