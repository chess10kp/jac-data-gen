import from operator { itemgetter }

"""
    Computes the weighted vote of each of the k-neighbors
    Adds up all votes of each entry. And retruns the key of the entry with the highest number of votes.
    """
def getPrediction(neighbors: list[list[object]], weights: list[float]) -> object {
    votes: dict[object, float] = {};
    for (x, neighbor) in enumerate(neighbors) {
        response = neighbor[-1];
        if response in votes {
            if weights[x] == 0.0 {
                votes[response] += 1;
            } else {
                votes[response] += 1 / weights[x];
            }
        } elif weights[x] == 0.0 {
            votes[response] = 1;
        } else {
            votes[response] = 1 / weights[x];
        }
    }
    sorted_votes = sorted(votes.items(), key=itemgetter(1), reverse=True);
    return sorted_votes[0][0];
}