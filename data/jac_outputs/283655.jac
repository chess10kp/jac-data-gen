"""
    Prints the average precision for each class and calculates micro mAP and macro mAP.
    @param aps: average precision for each class
    @param dictionary: mapping between label anc class name
    @return: micro mAP and macro mAP
    """
def calculate_map(aps: Any) -> object {
    total_instances = [];
    precisions = [];
    for (label, (average_precision, num_annotations)) in aps.items() {
        total_instances.append(num_annotations);
        precisions.append(average_precision);
    }
    if (sum(total_instances) == 0) {
        print('No test instances found.');
        return (0, 0);
    }
    micro_ap = (
        sum([(a * b) for (a, b) in zip(total_instances, precisions)])
        / sum(total_instances)
    );
    macro_ap = sum(precisions) / sum((x > 0) for x in total_instances);
    print('Micro mAP : {:.4f}'.format(micro_ap));
    print('Macro mAP: {:.4f}'.format(macro_ap));
    return (micro_ap, macro_ap);
}