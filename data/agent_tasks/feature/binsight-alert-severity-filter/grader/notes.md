# binsight-alert-severity-filter

`ListOpenAlerts` already declares `min_severity` but ignores it. Required:
- only open alerts with severity >= min_severity (order low < medium < high < critical), case-insensitive
- composes with the existing `hall_id` filter
- result ordered most-severe first (ties: any order; tests use distinct severities or sort)
Report shape unchanged: last report is {"open_alerts": [ {alert_id, severity, ...} ]}.
Tests run at binsight/jac_app/test_feature_hidden.jac (package-relative imports).
Regression: acknowledged alerts hidden, hall filter, report shape.
