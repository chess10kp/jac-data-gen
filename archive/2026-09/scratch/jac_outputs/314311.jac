"""format output of an `explain` mongo command

    Return a dictionary with 2 properties:

    - 'details': the origin explain result without the `serverInfo` part
      to avoid leaing mongo server version number
    - 'summary': the list of execution statistics (i.e. drop the details of
       candidate plans)

    if `explain_result` is empty, return `None`
    """
def _format_explain_result(explain_result: Any) -> object {
    if explain_result {
        explain_result.pop('serverInfo', None);
        if ('stages' in explain_result) {
            stats = [
                stage['$cursor']['executionStats']
                for stage in explain_result['stages']
                if ('$cursor' in stage)
            ];
        } else {
            stats = [explain_result['executionStats']];
        }
        return {'details': explain_result, 'summary': stats};
    }
    return None;
}