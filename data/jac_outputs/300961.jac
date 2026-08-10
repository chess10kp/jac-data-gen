"""
  read a list with words in gn
  """
def get_track_words(words_per_track: Any, hour_count: Any, lst: Any) -> object {
    i = hour_count * words_per_track;
    j = (i + words_per_track) - 1;
    return lst[i:j];
}