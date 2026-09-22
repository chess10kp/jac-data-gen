""" return file name with resulotion
    ex: generate_file_name('output', 'HD')
        >> 'output_HD.m3u8
    """
def generate_file_name(
    file_name: str | None = "playlist",
    resolution: str = "SD",
    extention: str | None = "m3u8"
) -> str {
    if file_name is None {
        file_name = "playlist";
    }
    if extention is None {
        extention = "m3u8";
    }
    return f"{file_name}_{resolution}.m3u8";
}