""""Decode the directory name in the format NNNk to a numeric size, where NNN is a number string"""
def efp_directory_size(directory_name: str) -> int {
    try {
        if directory_name[-1] == 'k' {
            return int(directory_name[:-1]);
        }
    } except ValueError {
        ;
    }
    return 0;
}