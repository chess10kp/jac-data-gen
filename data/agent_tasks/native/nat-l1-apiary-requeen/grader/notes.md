# nat-l1-apiary-requeen
Requirement -> test map: R1 root-direct hives only (nucleus test, deep_traversal mutant);
R2 queenless AND <3 brood (boundary test, brood_boundary); R3 temper>=4 OR (temper tests,
temper_strict, temper_requires_queenless); R4 checked/flagged fields; R5 single sorted report
(sorted test, unsorted_report, report_per_hive); R6 read-only (mutation test).
Alternative puts the logic on the node side (`can ... with RequeenAudit entry` + `visitor`).
