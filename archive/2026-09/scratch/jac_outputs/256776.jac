"""
    Get list of output Datareference
    """
def get_outputs(job: dict, configuration: dict, data: dict) -> list {
    outputs = [];
    if ("outputs" in job) {
        for data_name in job["outputs"] {
            data_object = data[data_name];
            outputs.append(data_object["pipelinedata_object"]);
        }
    }
    return outputs;
}