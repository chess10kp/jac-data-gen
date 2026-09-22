glob KIBI = 2 ** 10;
glob MEBI = 2 ** 20;
glob GIBI = 2 ** 30;

"""Returns file size qualifier."""
def get_qual(fsize: int | float) -> tuple[float, str] {
    if fsize > GIBI {
        fsize = fsize / GIBI;
        qual = 'Giga';
    } elif fsize > MEBI {
        fsize = fsize / MEBI;
        qual = 'Mega';
    } elif fsize > KIBI {
        fsize = fsize / KIBI;
        qual = 'Kilo';
    } else {
        qual = '';
    }
    fsize = round(fsize, 2);
    return (fsize, qual);
}