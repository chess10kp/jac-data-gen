"""
Return the ex_inquiry string corresponding to the specified objType.
This can be passed to the ex_inquiry_map() function to get the number of
objects of the specified objType
"""
def ex_obj_to_inq(objType: str) -> str | int {
    entity_dictionary = {
        'EX_ASSEMBLY': 'EX_INQ_ASSEMBLY',
        'EX_BLOB': 'EX_INQ_BLOB',
        'EX_EDGE_BLOCK': 'EX_INQ_EDGE_BLK',
        'EX_FACE_BLOCK': 'EX_INQ_FACE_BLK',
        'EX_ELEM_BLOCK': 'EX_INQ_ELEM_BLK',
        'EX_NODE_SET': 'EX_INQ_NODE_SETS',
        'EX_EDGE_SET': 'EX_INQ_EDGE_SETS',
        'EX_FACE_SET': 'EX_INQ_FACE_SETS',
        'EX_ELEM_SET': 'EX_INQ_ELEM_SETS',
        'EX_SIDE_SET': 'EX_INQ_SIDE_SETS',
        'EX_NODE_MAP': 'EX_INQ_NODES',
        'EX_EDGE_MAP': 'EX_INQ_EDGE',
        'EX_FACE_MAP': 'EX_INQ_FACE',
        'EX_ELEM_MAP': 'EX_INQ_ELEM'
    };
    return entity_dictionary.get(objType, -1);
}