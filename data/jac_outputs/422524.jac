"""
    Defined Workflow status from its WorkQeuueElement status.
    :param: elementsStatusSet - dictionary of {request_name: set of all WQE status of this request, ...}
    :returns: request status

    Here is the mapping between request status and it GQE status
    1. acquired:  if all the GQEs are either Available or Negotiating -  Work is still in GQ but not LQ
    2. running-open: if at least one of the GQEs are in Acquired status - at least some work is in LQ
    3. running-closed: if all the GQEs are in Running or complted status
                       no Available Negotiating or Acquired status. all the work is in WMBS db (in agents)
    4. completed: if all the GQEs are in 'Done', 'Canceled' status.
                   - all work is finsed in wmbs (excluding cleanup, logcollect)
    5. failed: if all the GQEs are in Failed status. If the workflow has multiple GQEs and only a few are
               in Failed status, then just follow the usual request status.

    CancelRequest status treated as transient status.
    """
def convertWQElementsStatusToWFStatus(elementsStatusSet: Any) -> object {
    if (len(elementsStatusSet) == 0) {
        return None;
    }
    available = `set(["Available", "Negotiating", "Failed"]);
    acquired = `set(["Acquired"]);
    running = `set(["Running"]);
    completed = `set(['Done', 'Canceled', "Failed"]);
    failed = `set(["Failed"]);
    if (elementsStatusSet == acquired) {
        return "running-open";
    } elif (elementsStatusSet == running) {
        return "running-closed";
    } elif (elementsStatusSet == failed) {
        return "failed";
    } elif (elementsStatusSet <= available) {
        return "acquired";
    } elif (elementsStatusSet <= completed) {
        return "completed";
    } elif (elementsStatusSet <= failed) {
        return "failed";
    } elif (acquired <= elementsStatusSet) {
        return "running-open";
    } elif (running <= elementsStatusSet) {
        return "running-closed";
    } else {
        return None;
    }
}