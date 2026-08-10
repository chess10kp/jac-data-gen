"""Reorder list from 0 degree -> 360 degree to -180 degree -> 180 degree."""
def reorder(mylist: list[int]) -> list[int] {
    old_mylist = mylist;
    mylist = old_mylist[180:];
    mylist += old_mylist[:180];
    return mylist;
}