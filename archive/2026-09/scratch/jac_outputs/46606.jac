type LabelStats = dict[str, dict[str, int | float | None]];

"""Calculate SOA-C-IoU-Top/Bot-40"""
def calc_split_class_average_iou(dict: LabelStats) -> tuple[float, float] {
    num_img_list = [[label, dict[label]["images_total"]] for label in dict.keys()];
    num_img_list.sort(key=lambda (x: list) { x[1]; });
    sorted_label_list = [x[0] for x in num_img_list];
    bottom_40_iou = 0.0;
    top_40_iou = 0.0;
    num_labels = len(dict.keys());
    for label in dict.keys() {
        if sorted_label_list.index(label) < 40 {
            if dict[label]["iou"] is not None and dict[label]["iou"] >= 0 {
                bottom_40_iou += dict[label]["iou"];
            }
        } elif dict[label]["iou"] is not None and dict[label]["iou"] >= 0 {
            top_40_iou += dict[label]["iou"];
        }
    }
    bottom_40_iou /= 0.5 * num_labels;
    top_40_iou /= 0.5 * num_labels;
    return (top_40_iou, bottom_40_iou);
}