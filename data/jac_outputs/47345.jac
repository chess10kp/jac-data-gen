"""Write a file specified by 'file_to_write' and returns (True,NOne) in case of success or (False, <error message>) in case of failure"""
def write_file(file_to_write: Any, text: Any) -> object {
    try {
        f = open(file_to_write, 'w');
        f.write(text);
        f.close();
    } except Exception as e {
        return (False, str(e));
    }
    return (True, None);
}