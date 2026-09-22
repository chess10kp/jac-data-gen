"""
    Converts the redshift of the snapshot from text to numerical,
    in a format compatible with the file names.
    E.g. float z = 2.16 <--- str z = 'z002p160'.
    """
def redshift_str2num(z: str) -> float {
    z = z.strip('z').replace('p', '.');
    return round(float(z), 3);
}