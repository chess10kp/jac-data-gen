"""
    message for different types of raid actions
    """
def get_success_message(action: Any, task_uri: Any) -> object {
    msg = "Successfully submitted {0} volume task.".format(action);
    status_message = {"msg": msg};
    if (task_uri is not None) {
        task_id = task_uri.split("/")[-1];
        status_message.update({"task_uri": task_uri, "task_id": task_id});
    }
    return status_message;
}