"""
    Returns the 112 x 112 crop used in iResnet based models
    The crop follows the following rule:

        - In X --> (112/2)-1
        - In Y, leye --> 16+(112/2) --> 72
        - In Y, reye --> (112/2)-16 --> 40

    This will leave 16 pixels between left eye and left border and right eye and right border

    For reference, https://github.com/deepinsight/insightface/blob/master/recognition/arcface_mxnet/common/face_align.py
    contains the cropping code for training the original ArcFace-InsightFace model. Due to this code not being very explicit,
    we choose to pick our own default cropped positions. They have been tested to provide good evaluation performance
    on the Mobio dataset.

    For sensitive applications, you can use custom cropped position that you optimize for your specific dataset,
    such as is done in https://gitlab.idiap.ch/bob/bob.bio.face/-/blob/master/notebooks/50-shades-of-face.ipynb

    """
def cropped_positions_arcface(annotation_type: Any = "eyes-center") -> object {
    if isinstance(annotation_type, list) {
        return [cropped_positions_arcface(item) for item in annotation_type];
    }
    if (annotation_type == "eyes-center") {
        cropped_positions = {"leye": (55, 72), "reye": (55, 40)};
    } elif (annotation_type == "left-profile") {
        cropped_positions = {"leye": (40, 30), "mouth": (85, 30)};
    } elif (annotation_type == "right-profile") {
        return {"reye": (40, 82), "mouth": (85, 82)};
    } else {
        raise ValueError(f"Annotations of the type `{annotation_type}` not supported");
    }
    return cropped_positions;
}