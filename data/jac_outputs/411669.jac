"""Creates GraphQL query."""
def prepare_query(site_id: str, condition: str) -> str {
    return """query getAssetResources($pagination: AssetsPaginationInputValidated) {
                    site(id: "%s") {
                        assetResources (
                            assetPagination: $pagination,
                            fields: [
                                "assetBasicInfo.name",
                                "assetBasicInfo.domain",
                                "assetBasicInfo.userName",
                                "assetBasicInfo.userDomain",
                                "assetBasicInfo.fqdn",
                                "assetBasicInfo.description",
                                "assetBasicInfo.type",
                                "assetBasicInfo.mac",
                                "assetBasicInfo.ipAddress",
                                "assetBasicInfo.firstSeen"
                                "assetBasicInfo.lastSeen"
                                "assetCustom.model",
                                "assetCustom.serialNumber",
                                "assetCustom.manufacturer",
                                "assetCustom.sku",
                                "assetCustom.firmwareVersion",
                                "assetCustom.purchaseDate",
                                "assetCustom.warrantyDate",
                                "assetCustom.comment",
                                "assetCustom.location",
                                "assetCustom.department",
                                "assetCustom.contact",
                                "assetCustom.dnsName",
                                "assetCustom.stateName",
                                "operatingSystem.caption",
                                "operatingSystem.productType",
                                "url"
                            ],
                            filters: {
                                conjunction: OR,
                                conditions: [%s]
                            }
                        ) {
                            total
                            pagination {
                                limit
                                current
                                next
                                page
                            }
                            items
                        }
                    }
                }""" % (site_id, condition);
}