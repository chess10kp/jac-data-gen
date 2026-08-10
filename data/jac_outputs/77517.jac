"""Retrieves text associated with a block.

    Args:
        block (dict): Information related to one Block Object
        blocks_map (dict): All Block objects analyzed by textract.

    Returns:
        str: Text associated with a Block.
    """
def get_text(block: Any, blocks_map: Any) -> object {
    text = '';
    if ('Relationships' in block) {
        for relationship in block['Relationships'] {
            if (relationship['Type'] == 'CHILD') {
                for child_id in relationship['Ids'] {
                    word = blocks_map[child_id];
                    if (word['BlockType'] == 'WORD') {
                        text += word['Text'] + ' ';
                    }
                }
            }
        }
    }
    return text;
}