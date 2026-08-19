def function(message: Any) -> object {
    message = message.strip();
    message_list = `list(message);
    message_list.reverse();
    reversed_message = ''.join(message_list);
    return reversed_message;
}



with entry {
    print(function('hello'));
    print(function('Racecar'));
    print(function('abcabc'));
}
