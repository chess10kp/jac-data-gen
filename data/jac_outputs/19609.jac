"""Returns a complete image filename string tailored to the spaceweather
site string by concatenating the input image filename (if) strings that
define the path, date, filename root, and the filename extension.
If verbose is truthy, then print the returned image filename string."""
def get_spaceweather_imagefile(
    if_path: str, if_date: str, if_filename: str, if_extension: str, verbose: bool
) -> str {
    sw_imagefile = if_path + if_date + "_" + if_filename + if_extension;
    if verbose {
        print("Output image file full path: \n{}\n".format(sw_imagefile));
    }
    return sw_imagefile;
}