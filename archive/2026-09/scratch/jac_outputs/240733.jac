"""
Inspect the summary data for a given tx_id and determine
whether modules should be created for the different data types.
"""
def determine_modules_for_dashboard(summaries: list[dict[str, str | int | float | None]], tx_id: str | int) -> dict[str, bool] {
    module_types = {'transactions_per_year': True, 'transactions_per_quarter': True};
    service_data = [data for data in summaries if data['service_id'] == tx_id];
    quarterly_data = [datum for datum in service_data if datum['type'] == 'quarterly'];
    seasonal_data = [datum for datum in service_data if datum['type'] == 'seasonally-adjusted'];
    if any(datum.get('total_cost') is not None for datum in seasonal_data) {
        module_types['total_cost'] = True;
    }
    if any(datum.get('cost_per_transaction') is not None for datum in seasonal_data) {
        module_types['cost_per_transaction'] = True;
    }
  digital_takeup = any(datum.get('digital_takeup') is not None for datum in seasonal_data)
        or any(datum.get('digital_takeup') is not None for datum in quarterly_data);
    if digital_takeup {
        module_types['digital_takeup'] = True;
    }
    return module_types;
}