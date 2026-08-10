"""Get the elements of the file name we need."""
def get_name(fname: str) -> dict[str, str] {
    if fname.endswith('.nii.gz') {
        fname = fname.replace('.nii.gz', '');
    }
    tmp = fname.split('_');
    elems = tmp[-4:-1];
    name_stuff: dict[str, str] = {};
    name_stuff['IC'] = elems[0][2:];
    name_stuff['Scan'] = elems[1][1:];
    name_stuff['Hemi'] = elems[2].upper();
    return name_stuff;
}