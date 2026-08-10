"""
Returns the type of item that has been scanned based on the UPC of the item
that has been scanned i.e. the "item_scanned" parameter.
"""
def get_barcode(item_scanned: str) -> str | None {
    match item_scanned {
        case '111111':
            return 'SINGLES';
        case '666666':
            return 'SMALL';
        case '242424':
            return 'LARGE';
        case '0':
            return 'done';
        case _:
            print("Oops! You entered an unrecognized Universal Price Code (UPC). Please enter an appropriate UPC for your item");
    }
}