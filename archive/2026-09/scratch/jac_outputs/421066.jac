"""
floors = [0 to M ]
elevator:
    max capacity of X people
    weight limit of Y lbs
N people gathered in floor[0] standing in a queue()
k: a kth numbered person
A[k] = weight, B[k] = target floor or dst ex)A[0] and B[0] => 0th person

count total number of times that elavator stops
"""
def solution(A: list[int], B: list[int], M: int, X: int, Y: int) -> int {
    stops = 0;
    queue = [(a, b) for (a, b) in zip(A, B)];
    while queue {
        (people, weight) = (X, Y);
        elevator = [];
        while queue and people and weight > 0 {
            values = queue[0];
            weight -= values[0];
            if weight < 0 {
                break;
            }
            elevator.append(values);
            queue.pop(0);
            people -= 1;
        }
        while elevator {
            values = elevator.pop(0);
            while elevator and elevator[0][1] == values[1] {
                elevator.pop(0);
            }
            stops += 1;
        }
        stops += 1;
    }
    return stops;
}