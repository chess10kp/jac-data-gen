glob READ_LENGTH = 150;
glob READ_OVERLAP = 50;

"""
    Creates reads of according to the parameters in the argument
    input: The full sequence as a string
    output: reads in string format INSIDE a list called "my_reads"
    """
def get_reads(seq_file: str) -> list[str] {
    my_reads: list[str] = [];
    read_pos = 0;
    while read_pos < len(seq_file) {
        my_reads.append(seq_file[read_pos:(read_pos + READ_LENGTH)]);
        read_pos += READ_LENGTH - READ_OVERLAP;
    }
    for x in my_reads {
        print(len(x));
    }
    return my_reads;
}