"""Generate Donation log url from args e.g. https://dons.wikimedia.fr/journal/2013-12"""
def url_from_args(year: int, month: int) -> str {
    return "https://dons.wikimedia.fr/journal/%04d-%02d" % (year, month);
}