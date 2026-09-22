""" Determine whether an edit is editorial (0) or content (1).
	This is dependent on whether there are substantial additions in content volume.

	It is only a content contribution if:
		1) both text and links/urls are added (not text in isolation)
		2) images are added.
	Editorial counts:
		- words only
		- categories
		- any deletions
	"""
def determine_edit_type(values: Any, previous_values: Any) -> object {
    changes = {key: (values[key] - previous_values.get(key, 0)) for key in values};
    if (changes["images"] > 0) {
        return "content";
    } elif ((changes["words"] > 0) and ((changes["links"] + changes["urls"]) > 0)) {
        return "content";
    } else {
        return "editorial";
    }
}