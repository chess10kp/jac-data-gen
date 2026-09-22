"""
Parameters
----------
hist_dict : Dictionary
    Histogram dictionary containing number of repeats with certain length.
filename : String
    Output file name.

Returns
-------
total : Int
    Total number of repeats found.
"""
def print_totals(hist_dict: dict[int, int], filename: str) -> int {
    keys = list(hist_dict.keys());
    keys.sort();
    file = open(filename, 'w');
    file.write('rep_num  total\n');
    total = 0;
    for rep_num in keys {
        repeats = hist_dict[rep_num];
        line = '{:7}  {}\n'.format(rep_num, repeats);
        file.write(line);
        total += repeats;
    }
    file.write('\nTotal: {}'.format(total));
    file.close();
    return total;
}