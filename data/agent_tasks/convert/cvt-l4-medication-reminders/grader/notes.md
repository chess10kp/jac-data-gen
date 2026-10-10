# cvt-l4-medication-reminders
Source Zirochkaa/medication-notification (MIT) @0b98154. FARM-style (Beanie, Telegram bot) L4 with a
two-hop relation chain. Hidden tests port the upstream model tests (soft-delete filtering, time-window
and day queries) onto uuid-tagged users and a random 19xx date so the persistent store can't leak
state between runs. Negatives: deleted meds listed, no-op soft delete, taken flag ignored, day match
too coarse, hour cap missing, strict time cut.
