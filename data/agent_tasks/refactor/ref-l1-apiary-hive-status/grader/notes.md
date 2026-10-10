# ref-l1-apiary-hive-status
Smell: string-typed status field on obj Hive compared against string literals everywhere.
Target: string-valued enum HiveStatus; label uses `.value` so text is unchanged.
Idiom targets: >=1 enum; Hive.status not typed str.
Negatives: requeened can't go queenless; double loss succeeds; enum name in label; weak hives ignored.
