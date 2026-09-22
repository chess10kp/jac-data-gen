"""Map coco.names class id to instances_val2014.json category id."""
def get_category_id(k: int) -> int {
    kk = k;
    if 12 <= k <= 24 {
        kk = k + 1;
    } elif 25 <= k <= 26 {
        kk = k + 2;
    } elif 27 <= k <= 40 {
        kk = k + 4;
    } elif 41 <= k <= 60 {
        kk = k + 5;
    } elif k == 61 {
        kk = k + 6;
    } elif k == 62 {
        kk = k + 8;
    } elif 63 <= k <= 73 {
        kk = k + 9;
    } elif 74 <= k <= 80 {
        kk = k + 10;
    }
    return kk;
}