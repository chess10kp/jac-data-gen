"""returns icon class based on file format"""
def _get_file_icon(item: str) -> str {
    extension = item.split('.')[-1].lower();
    if extension in ['xml', 'txt', 'json'] {
        return "file-text";
    }
    if extension in ['csv', 'xls'] {
        return "bar-chart-o";
    }
    if extension in ['shp', 'geojson', 'kml', 'kmz'] {
        return "globe";
    }
    return "file";
}