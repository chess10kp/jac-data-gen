"""
    construct a Jekyll yaml collection (a dictionary) from a menu dict
    example input:  {'ReadingNotes': ['Book_NeuralNetworksAndDeepLearning', 'test']}
    example output:  {'ReadingNotes_Book_NeuralNetworksAndDeepLearning': {'output': True,
    'permalink': '/ReadingNotes/Book_NeuralNetworksAndDeepLearning/:path'},
    'ReadingNotes_test': {'output': True, 'permalink': '/ReadingNotes/test/:path'}}
    """
def collections_from_dict(dic: dict[str, list[str]]) -> dict[str, dict[str, bool | str]] {
    collection = {};
    for (menu_name_en, directories) in dic.items() {
        for collection_directory in directories {
            menu_item = 'collection_' + menu_name_en + '_' + collection_directory;
            permalink = '/{0}/{1}/:path'.format(menu_name_en, collection_directory);
            collection[menu_item] = {'output': True, 'permalink': permalink};
        }
    }
    return collection;
}