""" Insert front a game into the gamelog """
def insert_gamelog(predict_gamelog: list[list[int]], training_gamelog: list[list[int]]) -> list[list[int]] {
    return training_gamelog + predict_gamelog;
}