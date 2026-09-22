"""Check whether the type is allowed for a file history file.

    :param filename: name of the file
    :return: True or False
    """
def allowed_file_history(filename: str) -> bool {
    return (('.' in filename) and (filename.rsplit('.', 1)[1].lower() in ['json']));
}

test "t0" {
    assert (allowed_file_history('test.history.xml') == False);;
}

test "t1" {
    assert (allowed_file_history("test") == False);;
}

test "t2" {
    assert (allowed_file_history("test.zip") == False);;
}

test "t3" {
    assert (allowed_file_history("test.json.tar.gz") == False);;
}

test "t4" {
    assert (
        allowed_file_history(r'C:\Users\some_name\some_file.JSON.txt.txt') == False
    );;
}

test "t5" {
    assert (allowed_file_history("history.json.bkup") == False);;
}

test "t6" {
    assert (allowed_file_history(r'C:\Users\some_name\some_file.JSON.txt') == False);;
}

test "t7" {
    assert (
        allowed_file_history('data/file_history/2020-07-01/2020-07-01-0100-00-00.json')
        == True
    );;
}

test "t8" {
    assert (allowed_file_history('this_is_not_a_history_file.html') == False);;
}

test "t9" {
    assert (allowed_file_history('valid_file_name.json') == True);;
}

test "t10" {
    assert (
        allowed_file_history(
            '2018-04-01_10-54-02-f11c2c61-8f50-4a4f-b65a-d385d28a4319.csv'
        )
        == False
    );;
}

test "t11" {
    assert (allowed_file_history("history.json") == True);;
}

test "t12" {
    assert (allowed_file_history(r'C:\Users\some_name\some_file.json.txt') == False);;
}

test "t13" {
    assert (allowed_file_history("history") == False);;
}

test "t14" {
    assert (allowed_file_history('invalid_file_name.xml') == False);;
}

test "t15" {
    assert (
        allowed_file_history(
            '2018-04-01_10-54-02-f11c2c61-8f50-4a4f-b65a-d385d28a4319.json'
        )
        == True
    );;
}

test "t16" {
    assert (allowed_file_history(r'C:\Users\some_name\some_file.TXT') == False);;
}

test "t17" {
    assert (allowed_file_history("test.tar.gz") == False);;
}

test "t18" {
    assert (allowed_file_history('this_is_a_history_file.json') == True);;
}

test "t19" {
    assert (allowed_file_history("test.JSON") == True);;
}

test "t20" {
    assert (allowed_file_history('hello.txt') == False);;
}

test "t21" {
    assert (allowed_file_history('history.xml') == False);;
}

test "t22" {
    assert (
        allowed_file_history(
            '2018-04-01_10-54-02-f11c2c61-8f50-4a4f-b65a-d385d28a4319.txt'
        )
        == False
    );;
}

test "t23" {
    assert (allowed_file_history('history.json') == True);;
}

test "t24" {
    assert (
        allowed_file_history('2018-04-01_10-54-02-f11c2c61-8f50-4a4f-b65a-d385d28a4319')
        == False
    );;
}

test "t25" {
    assert (allowed_file_history("test.json.zip") == False);;
}

test "t26" {
    assert (
        allowed_file_history(
            '2018-04-01_10-54-02-f11c2c61-8f50-4a4f-b65a-d385d28a4319.py'
        )
        == False
    );;
}

test "t27" {
    assert (allowed_file_history(r'C:\Users\some_name\some_file.TXT.txt') == False);;
}

test "t28" {
    assert (
        allowed_file_history('data/file_history/2020-07-01/2020-07-01-0100-00-00.py')
        == False
    );;
}

test "t29" {
    assert (allowed_file_history("history.txt") == False);;
}

test "t30" {
    assert (allowed_file_history(r'C:\Users\some_name\some_file.txt') == False);;
}

test "t31" {
    assert (allowed_file_history("test.json") == True);;
}

test "t32" {
    assert (allowed_file_history('hello.json') == True);;
}
