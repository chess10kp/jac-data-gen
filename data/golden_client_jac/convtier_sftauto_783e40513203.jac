def cube_positive_integers(nums: Any) -> object {
    positive_nums = `set();
    for num in nums {
        if (num > 0) {
            positive_nums.add(num);
        }
    }
    cubes = [(num ** 3) for num in positive_nums];
    cubes.sort();
    return cubes;
}



with entry {
    print(cube_positive_integers([81]));
    print(cube_positive_integers([]));
    print(cube_positive_integers([100]));
}
