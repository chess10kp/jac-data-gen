"""Generate the id for a frontend ip configuration"""
def frontend_ip_configuration_id(
    subscription_id: Any, resource_group_name: Any, appgateway_name: Any, name: Any
) -> object {
    return '/subscriptions/{0}/resourceGroups/{1}/providers/Microsoft.Network/applicationGateways/{2}/frontendIPConfigurations/{3}'.format(
        subscription_id, resource_group_name, appgateway_name, name
    );
}