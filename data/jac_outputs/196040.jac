"""
    Refactors `self::` and `super::` uses to absolute paths.
    :param dependency:
    :param current_path:
    :return:
    """
def absolute_path(dependency: Any, current_path: Any) -> object {
    path_elements = dependency.split('::');
    if (path_elements[0] == 'self') {
        path_elements[0] = current_path;
    } elif (path_elements[0] == 'super') {
        count = 0;
        while (path_elements[0] == 'super') {
            path_elements.pop(0);
            count += 1;
        }
        path_elements.insert(0, '::'.join(current_path.split('::')[:-count]));
    } else {
        return dependency;
    }
    return '::'.join(path_elements);
}