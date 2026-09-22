"""
    Store metrics in the same format as Cloudwatch in case we want to use
    Cloudwatch as a metrics store later
    :param job:  JSON job data struture from dynamodb
    """
def getJobMetricDimensions(job: Any) -> object {
    ret = {};
    dimensions = [];
    filters = {};
    job_dim = {};
    job_dim['Name'] = 'jobId';
    job_dim['Value'] = job['id'];
    dimensions.append(job_dim);
    filters['jobId'] = job['id'];
    filters['account'] = job['queue'].split(':')[4];
    filters['region'] = job['queue'].split(':')[3];
    queue_dim = {};
    queue_dim['Name'] = 'queue';
    queue_dim['Value'] = job['queue'];
    dimensions.append(queue_dim);
    filters['queue'] = job['queue'];
    filters['queueName'] = job['queue'].split('/')[1];
    for key in job['userMetadata'] {
        value = job['userMetadata'][key];
        dimension = {};
        dimension['Name'] = key;
        dimension['Value'] = value;
        dimensions.append(dimension);
        filters[key] = value;
        if (key not in job) {
            job[key] = value;
        }
    }
    ret['dimensions'] = dimensions;
    ret['filters'] = filters;
    return ret;
}