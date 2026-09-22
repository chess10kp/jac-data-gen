"""
  Defines the contents of `teacher-input.txt` to which `run.sh`
  concatenates the student submission as the exercise is posted to
  MOOC Grader for grading.

  Generates 3 random numbers and forms a string containing
  the MathCheck configuration for this exercise.
  """
def teacher_input(random_numbers: list[int]) -> str {
    return (
        "arithmetic\n"
        + "f_nodes 3\n"
        + "{}/3^({}) + {}\n".format(
            random_numbers[0], random_numbers[1], random_numbers[2]
        )
    );
}