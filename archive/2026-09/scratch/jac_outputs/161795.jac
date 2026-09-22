import from collections { OrderedDict }

"""Transform to convert SDK file/dir list output to something that
more clearly distinguishes between files and directories."""
def transform_file_output(result: list[dict[str, object]] | dict[str, object]) -> list[OrderedDict[str, str | int]] {
    new_result = [];
    iterable = result if isinstance(result, list) else result.get('items', result);
    for item in iterable {
        new_entry = OrderedDict();
        entity_type = item['type'];
        is_dir = entity_type == 'dir';
        new_entry['Name'] = item['name'] + '/' if is_dir else item['name'];
        new_entry['Content Length'] = ' ' if is_dir else item['properties']['contentLength'];
        new_entry['Type'] = item['type'];
        new_entry['Last Modified'] = item['properties']['lastModified'] or ' ';
        new_result.append(new_entry);
    }
    return sorted(new_result, key=lambda (k: OrderedDict[str, str | int]) { k['Name']; });
}