"""Calculate accuracy for multiple choice tasks."""
def calculate_multiple_choice_task_metrics(pred_dict: dict[str, float], labels_dict: dict[str, int | str]) -> float {
    assert len(pred_dict) == len(labels_dict);
    instance: dict[str, tuple[str, float]] = {};
    for sub_id in pred_dict {
        (ins_id, choice_id) = sub_id.split("_");
        prob = pred_dict[sub_id];
        if ins_id not in instance {
            instance[ins_id] = (choice_id, prob);
        } elif prob > instance[ins_id][1] {
            instance[ins_id] = (choice_id, prob);
        }
    }
    correct_count = 0;
    for sub_id in labels_dict {
        (ins_id, choice_id) = sub_id.split("_");
        label = int(labels_dict[sub_id]);
        if label == 1 and choice_id == instance[ins_id][0] {
            correct_count += 1;
        }
    }
    return correct_count / len(instance);
}