""" use a different account in each xdist worker """
def local_rank(worker_id: str) -> int {
    if "gw" in worker_id {
        return int(worker_id.replace("gw", ""));
    } elif worker_id == "master" {
        return 0;
    }
    raise RuntimeError("Can not get rank from worker_id={}".format(worker_id));
}