def allowed_file_history(filename: str) -> bool:
    """Check whether the type is allowed for a file history file.

    :param filename: name of the file
    :return: True or False
    """
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ['json']

assert allowed_file_history('test.history.xml') == False
assert allowed_file_history("test") == False
assert allowed_file_history("test.zip") == False
assert allowed_file_history("test.json.tar.gz") == False
assert allowed_file_history(r'C:\Users\some_name\some_file.JSON.txt.txt') == False
assert allowed_file_history(
    "history.json.bkup"
) == False
assert allowed_file_history(r'C:\Users\some_name\some_file.JSON.txt') == False
assert allowed_file_history(
    'data/file_history/2020-07-01/2020-07-01-0100-00-00.json') == True
assert allowed_file_history(
    'this_is_not_a_history_file.html'
) == False
assert allowed_file_history(
    'valid_file_name.json'
) == True
assert allowed_file_history(
    '2018-04-01_10-54-02-f11c2c61-8f50-4a4f-b65a-d385d28a4319.csv'
) == False
assert allowed_file_history(
    "history.json"
) == True
assert allowed_file_history(r'C:\Users\some_name\some_file.json.txt') == False
assert allowed_file_history(
    "history"
) == False
assert allowed_file_history(
    'invalid_file_name.xml'
) == False
assert allowed_file_history(
    '2018-04-01_10-54-02-f11c2c61-8f50-4a4f-b65a-d385d28a4319.json'
) == True
assert allowed_file_history(r'C:\Users\some_name\some_file.TXT') == False
assert allowed_file_history("test.tar.gz") == False
assert allowed_file_history(
    'this_is_a_history_file.json'
) == True
assert allowed_file_history("test.JSON") == True
assert allowed_file_history('hello.txt') == False
assert allowed_file_history('history.xml') == False
assert allowed_file_history(
    '2018-04-01_10-54-02-f11c2c61-8f50-4a4f-b65a-d385d28a4319.txt'
) == False
assert allowed_file_history('history.json') == True
assert allowed_file_history(
    '2018-04-01_10-54-02-f11c2c61-8f50-4a4f-b65a-d385d28a4319'
) == False
assert allowed_file_history("test.json.zip") == False
assert allowed_file_history(
    '2018-04-01_10-54-02-f11c2c61-8f50-4a4f-b65a-d385d28a4319.py'
) == False
assert allowed_file_history(r'C:\Users\some_name\some_file.TXT.txt') == False
assert allowed_file_history(
    'data/file_history/2020-07-01/2020-07-01-0100-00-00.py') == False
assert allowed_file_history(
    "history.txt"
) == False
assert allowed_file_history(r'C:\Users\some_name\some_file.txt') == False
assert allowed_file_history("test.json") == True
assert allowed_file_history('hello.json') == True
