"""Get mailpiece image url."""
def _get_mailpiece_image(row: Any) -> object {
    try {
        return row.find('img', {'class': 'mailpieceIMG'}).get('src');
    } except AttributeError {
        return None;
    }
}