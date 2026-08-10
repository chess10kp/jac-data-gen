"""It adds the"""
def area_of_imgblocks(imgblocks: list[dict[str, int]]) -> int {
    sum_areas = 0;
    for imgblock in imgblocks {
        block_area = imgblock['width'] * imgblock['height'];
        sum_areas = sum_areas + block_area;
    }
    return sum_areas;
}