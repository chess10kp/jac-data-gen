"""Return URL to file hosted in the pax repository master branch"""
def pax_file(x: str) -> str {
    'https://raw.githubusercontent.com/XENON1T/pax/master/pax/data/' + x
}