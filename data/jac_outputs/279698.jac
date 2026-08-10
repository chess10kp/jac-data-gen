"""Generate a summary of management nodes locked and any errors that occurred."""
def genSummary(compList: Any, compLockList: Any, lockRet: Any) -> object {
    print("Operation Summary");
    print("=================");
    print(("Found %d management nodes and BMCs:" % len(compList)));
    print(("    " + ','.join(compList)));
    print(("Found %d management nodes and BMCs to lock:" % len(compLockList)));
    print(("    " + ','.join(compLockList)));
    if (lockRet['Counts']['Success'] > 0) {
        print(
            (
                "Successfully locked %d management nodes and BMCs:"
                % lockRet['Counts']['Success']
            )
        );
        compStr = ','.join(lockRet['Success']['ComponentIDs']);
        print(("    " + compStr));
    }
    if (lockRet['Counts']['Failure'] > 0) {
        print(
            (
                "Failed to lock %d management nodes and BMCs:"
                % lockRet['Counts']['Failure']
            )
        );
        for comp in lockRet['Failure'] {
            print(("    " + comp['ID'] + " - " + comp['Reason']));
        }
    }
    print("");
    return lockRet['Counts']['Failure'];
}