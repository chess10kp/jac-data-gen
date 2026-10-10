# binsight-alert-notes

New node type + traversal. Required interface (request.md):
- walker `AddAlertNote(alert_id, note_id, author, text, created_at)` -> last report {"alert_id","added","note_count"}
- walker `ListAlertNotes(alert_id)` -> last report {"alert_id","found","notes":[{note_id,author,text,created_at}]} oldest first
- notes are graph nodes (`AlertNote`) connected FROM their Alert (tests traverse `[alert -->][?:AlertNote]`
  and require none hanging off root); duplicate note_id on the same alert ignored; blank text / unknown alert -> added False.
Node/edge names: tests import `AlertNote` from domain/nodes.jac (named in the request); the edge type is free.
Regression: open-alert listing + acknowledge unchanged.
