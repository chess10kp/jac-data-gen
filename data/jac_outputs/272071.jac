"""Extract text content between XML open and close tags for node_name."""
def get_value_from_xml_string(xml_text: str, node_name: str) -> str {
    start_node_name = "<" + node_name + ">";
    str_position = xml_text.find(start_node_name) + len(start_node_name);
    end_node_name = "</" + node_name + ">";
    end_position = xml_text.find(end_node_name);
    return xml_text[str_position:end_position];
}