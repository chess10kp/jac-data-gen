"""Accuracy as percentage of examples that received rewards."""
def task_accuracy_metrics(reward_list: list[int | float]) -> float {
    total = sum(reward_list);
    accuracy = total * 100 / float(len(reward_list));
    print("Total Reward: %s, Accuracy: %s %%" % (total, accuracy));
    return accuracy;
}