"""
    Method to extract attributes from kind desctiption and complete the missing ones in the resource description
    """
def recursive_for_default_attributes(attributes: Any) -> object {
    att_http = `list();
    for key in attributes.keys() {
        if (`type(attributes[key]) is `dict) {
            items = recursive_for_default_attributes(attributes[key]);
            for item in items {
                if not item.find('{') {
                    att_http.append((key + item));
                } else {
                    att_http.append((key + "." + item));
                }
            }
        } else {
            attributes = [""];
            return attributes;
        }
    }
    final_att = `list();
    for item in att_http {
        if item.endswith('.') {
            final_att.append(item[:-1]);
        } else {
            final_att.append(item);
        }
    }
    return final_att;
}