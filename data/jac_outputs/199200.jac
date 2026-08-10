"""STOMP abort transaction command.

Rollback whatever actions in this transaction.
"""
def abort(transactionid: str) -> str {
    return "ABORT\ntransaction: %s\n\n\x00\n" % transactionid;
}