import operator;
import itertools;

"""Return the contiguous job ids in the given list.

    Returns
    -------
    contiguous_job_ids : str
        The job ids organized in contiguous sets.

    """
def find_contiguous_ids(job_ids: list[int]) -> str {
    contiguous_job_ids = [];
    for (k, g) in itertools.groupby(
        enumerate(job_ids), lambda (x: tuple[int, int]) { x[0] - x[1] }
    ) {
        group = list(map(operator.itemgetter(1), g));
        if len(group) == 1 {
            contiguous_job_ids.append(str(group[0]));
        } else {
            contiguous_job_ids.append('{}-{}'.format(group[0], group[-1]));
        }
    }
    return ','.join(contiguous_job_ids);
}