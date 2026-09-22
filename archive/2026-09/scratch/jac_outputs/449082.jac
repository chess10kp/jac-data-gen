"""Convert bytes to mb or kb depending on scale"""
def convert_size(size: Any) -> object {
    kb = size // 1000;
    mb = round((kb / 1000), 1);
    if (kb > 1000) {
        return f'{mb:,.1f} MB';
    } else {
        return f'{kb:,d} KB';
    }
}