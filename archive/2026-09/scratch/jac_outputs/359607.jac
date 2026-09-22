"""
    Modify nested event dictionary to make it follow a more flattened
    approach so as to use full functionality of the run.py function
    `find_value(name, obj)`. The dictionaries of the format
    {
        "event_type":"http",
        "http":{
            "hostname":"supportingfunctions.us.newsweaver.com",
            "http_port":443
            }
    }

    will be converted to

    {
        "event_type":"http",
        "http.hostname":"supportingfunctions.us.newsweaver.com",
        "http.http_port":443
    }
    """
def modify_eve_dict(eve_dict: Any) -> object {
    modified = {};
    """
        Recursive function to flatten the nested dictionaries.
        """;
    def flatten(x: Any, name: Any = '') -> object {
        if (`type(x) is `dict) {
            for val in x {
                flatten(x[val], (name + val + '.'));
            }
        } elif (`type(x) is `list) {
            i = 0;
            for val in x {
                name = name.rstrip('.');
                flatten(val, (name + '[' + str(i) + ']' + '.'));
                i += 1;
            }
        } elif (name[:-1] not in ["flow.start", "flow.end"]) {
            modified[name[:-1]] = x;
        }
    }
    flatten(eve_dict);
    return modified;
}