"""
    return the dataset (list) of mushroom from path file
    :param path: path of mushroom dataset
    :return: mushroom dataset
    """
def loadMushroomDataSet(path: Any) -> object {
    mushroomDataset = None;
    try {
        mushroomDataset = [line.split() for line in open(path).readlines()];
    } except Exception as e {
        print(e);
    } finally {
        return mushroomDataset;
    }
}