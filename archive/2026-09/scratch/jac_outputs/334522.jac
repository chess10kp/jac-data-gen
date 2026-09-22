"""string -> bool

  Write a function check_ends (astring), which takes in a string astring and returns True if the first character in astring is the same as the last character in astring. It returns False otherwise. The check_ends function
  does not have to work on the empty string (the string "")

  >>> check_ends('no match')
  False
  >>> check_ends('hah! a match')
  True
  """
def check_ends(astring: Any) -> object {
    return (astring[0] == astring[-1]);
}