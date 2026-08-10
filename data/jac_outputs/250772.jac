"""
    Examples
    --------
    {
        "head":["PC","Mac","Windows","Ubuntu"],
        "body":[
            ["X1","x","o","o"],
            ["Surface","x","o","o"],
            ["MacBook Air","o","o","o"]
        ]
    }
    """
def dict_to_table(_dict: dict[str, list[str] | list[list[str]]]) -> str {
    dict_table = "";
    head = _dict["head"] as list[str];
    dict_table += "|" + "|".join([str(n) for n in head]) + "|\n";
    dict_table += "|" + "-|" * len(head) + "\n";
    body = _dict["body"] as list[list[str]];
    for row in body {
        dict_table += "|" + "|".join([str(n) for n in row]) + "|\n";
    }
    return dict_table;
}