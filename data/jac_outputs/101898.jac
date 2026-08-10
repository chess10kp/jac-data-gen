"""Generating data shapes with img resizing for tensorflow datasets depending on if we need to load the masks or not
    outputs:
        data shapes with masks = output data shapes for (images, ground truth boxes, ground truth labels, masks, mask id labels)
        data shapes without masks = output data shapes for (images, ground truth boxes, ground truth labels)
    """
def get_data_shapes_resize(masks: bool) -> tuple[list[None], list[None], list[None], list[None], list[None]] | tuple[list[None], list[None], list[None]] {
    if masks {
        return ([None, None, None], [None, None], [None], [None, None, None], [None]);
    }
    return ([None, None, None], [None, None], [None]);
}