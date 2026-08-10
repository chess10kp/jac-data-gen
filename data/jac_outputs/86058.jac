"""Create a properly formatted single indicator payload.

    {
      "action": "string",
      "applied_globally": true,
      "description": "string",
      "expiration": "2021-10-22T10:40:39.372Z",
      "host_groups": [
        "string"
      ],
      "metadata": {
        "filename": "string"
      },
      "mobile_action": "string",
      "platforms": [
        "string"
      ],
      "severity": "string",
      "source": "string",
      "tags": [
        "string"
      ],
      "type": "string",
      "value": "string"
    }
    """
def indicator_object(passed_keywords: dict) -> dict {
    returned_payload = {};
    action = passed_keywords.get("action", None);
    if action {
        returned_payload["action"] = action;
    }
    applied_globally = passed_keywords.get("applied_globally", None);
    if applied_globally {
        returned_payload["applied_globally"] = applied_globally;
    }
    description = passed_keywords.get("description", None);
    if description {
        returned_payload["description"] = description;
    }
    expiration = passed_keywords.get("expiration", None);
    if expiration {
        returned_payload["expiration"] = expiration;
    }
    host_groups = passed_keywords.get("host_groups", None);
    if host_groups {
        returned_payload["host_groups"] = host_groups;
    }
    metadata = passed_keywords.get("metadata", None);
    if metadata {
        returned_payload["metadata"] = metadata;
    }
    filename = passed_keywords.get("filename", None);
    if filename {
        returned_payload["metadata"] = {"filename": filename};
    }
    mobile_action = passed_keywords.get("mobile_action", None);
    if mobile_action {
        returned_payload["mobile_action"] = mobile_action;
    }
    platforms = passed_keywords.get("platforms", None);
    if platforms {
        returned_payload["platforms"] = platforms;
    }
    severity = passed_keywords.get("severity", None);
    if severity {
        returned_payload["severity"] = severity;
    }
    source = passed_keywords.get("source", None);
    if source {
        returned_payload["source"] = source;
    }
    tags = passed_keywords.get("tags", None);
    if tags {
        returned_payload["tags"] = tags;
    }
    type_val = passed_keywords.get("type", None);
    if type_val {
        returned_payload["type"] = type_val;
    }
    value = passed_keywords.get("value", None);
    if value {
        returned_payload["value"] = value;
    }
    id_val = passed_keywords.get("id", None);
    if id_val {
        returned_payload["id"] = id_val;
    }
    return returned_payload;
}