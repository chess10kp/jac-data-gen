# nat-l4-warehouse-picking
Multi-module: agent creates picking.jac and edits main.jac (entry wiring); layout.jac/seed.jac read-only context.
Run gate: jac run main.jac must print 'picked 5 lines, short 4 units' (bolt 40+10, nut 10+2, washer 5 -> short 4).
Alternative: eager while-loop chain follow, untyped-arrow filters, summary helper in main.
