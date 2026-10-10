# ref-l4-film-callsheet
Smell: `Production` bucket node (isinstance scan) with crew dict, scene dict-of-dicts and a list of assignment dicts; department strings + if-chain prep; all bodies inline.
Target: callsheet.jac = interface (enum Department; nodes Crew/ShootDay/Scene; edges Scheduled, AssignedTo{early}; walkers CallSheet / CrewDays with ability decls; 12 function decls); callsheet.impl.jac = 17 impl blocks.
Idiom targets: node>=3, edge>=2, walker>=2, enum>=1, edge_filters>=1, visits>=2, dict_fields==0 (walker dict fields are fine), isinstance==0, annex_impls>=8 (7 public functions + 5 walker abilities in any sensible split).
Behaviour: call time = min over the day's assigned scenes of start - prep(dept) - early; lines sorted by (time, name); dept printed uppercased; locations include scenes with nobody assigned.
Negatives: latest_scene, early_added, all_days, camera_prep_wrong, crew_days_duplicates.
