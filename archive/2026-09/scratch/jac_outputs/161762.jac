"""
As tag list can be full of in unnecessary data, we want to limit this list to include only the ID and Name fields.
In addition, returns set of the found tag ids.

Some tags have a field called inherited. When it is set to 1 it says that it is an event's tag.
Otherwise (if it is set to 0 or not exists) it says that it is an attribute's tag.
If the data is event's (is_event_level = true) we would like to add to tag_set_ids all the tags
(event ones and the event's attribute tags ones as it is part of the event scope).
If the data is attribute's (is_event_level = false), and the tag is only related to an attribute
we would like to add it to tag_set_ids. In any other case, we won't add the tag.
"""
def limit_tag_output_to_id_and_name(
    attribute_dict: dict[str, object],
    is_event_level: bool
) -> tuple[list[dict[str, object]], set[object]] {
    output = [];
    tag_set_ids = set();
    tags_list = attribute_dict.get('Tag', []) as list[dict[str, object]];
    for tag in tags_list {
        is_event_tag = tag.get('inherited', 0);
        tag_id = tag.get('id');
        if is_event_level {
            tag_set_ids.add(tag_id);
        } elif not is_event_tag {
            tag_set_ids.add(tag_id);
        }
        output.append({'ID': tag_id, 'Name': tag.get('name')});
    }
    return (output, tag_set_ids);
}