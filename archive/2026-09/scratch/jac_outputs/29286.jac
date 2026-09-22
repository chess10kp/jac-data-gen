"""This is a simple check to see if the final OOF ROC-AUC score is above 0.75. If it is, we return True; otherwise, we return
    False. As input, your do_full_save functions should expect an Experiment's result dictionary. This is actually the dictionary
    that gets saved as the Experiment's "description" file, so for more information on what's in there, look at any description
    file or see :attr:`hyperparameter_hunter.recorders.DescriptionRecorder.result` (the object passed to `do_full_save`)"""
def do_full_save(experiment_result: dict[str, dict[str, dict[str, float]]]) -> bool {
    experiment_result["final_evaluations"]["oof"]["roc_auc_score"] > 0.75
}