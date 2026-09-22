"""Break list into fixed, n-sized chunks. The final element of the new list will be n-sized or less."""
def chunkFx(mylist: list, n: int) -> list {
    return [mylist[i:i + n] for i in range(0, len(mylist), n)];
}