"""Given an array of can msgs, remove the messages that have  ids
    NOT in frame_ids_to_keep and return. If the data field is in bytearray
    format it will be changed to str.
    """
def filter_messages_keep(frame_ids_to_keep: list[int], array_of_msgs: list[tuple[int, object, str | bytearray, object]]) -> list[tuple[int, object, str, object]] {
    filtered_arr = [];
    for msg in array_of_msgs {
        (frame_id, _, data, bus) = msg;
        if type(data) != str {
            msg = (frame_id, _, str(data), bus);
        }
        for id_to_keep in frame_ids_to_keep {
            if frame_id == id_to_keep {
                filtered_arr.append(msg);
            }
        }
    }
    return filtered_arr;
}