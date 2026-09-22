"""Generate the completed SQL query command."""
def generate_sql_query_cmd(
    sql_event_name_condition_arg: str,
    sql_event_time_condition_arg: str
) -> str {
    return (
        "SELECT ChannelID, StartTime, EndTime, EventsTable.event_name FROM (SELECT ClipID, ChannelID, StartTime, EndTime FROM AVClip UNION SELECT ClipID, ChannelID, StartTime, EndTime FROM RecentAVClip) AS AVClipsTable, (SELECT EventClip.*, ConditionalEvent.event_name from EventClip, (SELECT event_his_id,event_name FROM EventHistory WHERE "
        + sql_event_time_condition_arg
        + " and "
        + sql_event_name_condition_arg
        + ") As ConditionalEvent Where EventClip.event_his_id = ConditionalEvent.event_his_id) AS EventsTable WHERE AVClipsTable.ClipID = EventsTable.clip_id"
    );
}