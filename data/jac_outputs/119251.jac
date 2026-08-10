"""
Method to get the list of time
frames that are to be included

Returns scrub_input_string for 3dCalc in scrubbing workflow,
e.g. " 4dfile.nii.gz[0,1,2,..100] "
"""
def get_indx(scrub_input: str, frames_in_1D_file: list[int]) -> str {
    return scrub_input + '[' + ','.join(str(x) for x in frames_in_1D_file) + ']';
}