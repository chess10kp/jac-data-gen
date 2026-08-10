"""
    :param data: this is a caching efficiency dictionary in a string format
    :return: the python dictionary format of the data string
    """
def convertJsonToDictionary(data: Any) -> object {
    output = {
        "#Payloads": [],
        "#queries": [],
        "#uniqueQueries": [],
        "PayloadSize (MB)": [],
        "folders": []
    };
    data = data.strip('{}');
    componenets = data.split(',"');
    folders_value = '';
    for comp in componenets[4:] {
        if folders_value {
            folders_value += ',"';
        }
        folders_value += comp;
    }
    componenets = componenets[:4] + [folders_value];
    for comp in componenets {
        elements = comp.split(':');
        (key, value) = (elements[0].strip('"'), elements[1].strip('[]'));
        if (key == "folders") {
            value = value.split('","');
            for val in value {
                val = val.strip('"');
                output["folders"].append(val);
            }
        } else {
            value = value.split(',');
            if (key == "PayloadSize (MB)") {
                output[key] = [float(val) for val in value];
            } else {
                output[key] = [int(val) for val in value];
            }
        }
    }
    return output;
}