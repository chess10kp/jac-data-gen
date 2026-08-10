"""
    Cluster one dimension data with Jenks Natural Breaks.
    https://stackoverflow.com/questions/28416408/scikit-learn-how-to-run-kmeans-on-a-one-dimensional-array
    """
def gen_cluster_1d(data_list: list[float], number_class: int) -> list[float] {
    data_list.sort();
    n = len(data_list);
    mat1: list[list[int]] = [[0 for _ in range(number_class + 1)] for _ in range(n + 1)];
    mat2: list[list[float]] = [[0.0 for _ in range(number_class + 1)] for _ in range(n + 1)];
    for i in range(1, number_class + 1) {
        mat1[1][i] = 1;
        mat2[1][i] = 0.0;
        for j in range(2, n + 1) {
            mat2[j][i] = float('inf');
        }
    }
    v = 0.0;
    for l in range(2, n + 1) {
        s1 = 0.0;
        s2 = 0.0;
        w = 0.0;
        for m in range(1, l + 1) {
            i3 = (l - m) + 1;
            val = float(data_list[i3 - 1]);
            s2 += val * val;
            s1 += val;
            w += 1;
            v = s2 - (s1 * s1) / w;
            i4 = i3 - 1;
            if i4 != 0 {
                for j in range(2, number_class + 1) {
                    if mat2[l][j] >= v + mat2[i4][j - 1] {
                        mat1[l][j] = i3;
                        mat2[l][j] = v + mat2[i4][j - 1];
                    }
                }
            }
        }
        mat1[l][1] = 1;
        mat2[l][1] = v;
    }
    k = n;
    kclass = [min(data_list) for _ in range(number_class + 1)];
    kclass[number_class] = float(data_list[n - 1]);
    count_num = number_class;
    while count_num >= 2 {
        idx = int(mat1[k][count_num] - 2);
        kclass[count_num - 1] = data_list[idx];
        k = int(mat1[k][count_num] - 1);
        count_num -= 1;
    }
    return kclass;
}