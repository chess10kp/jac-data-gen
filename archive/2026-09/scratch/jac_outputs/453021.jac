"""Concatenate TAS components into a single field for internal use."""
def format_internal_tas(row: dict[str, str]) -> str {
    tas = ''.join(
        [
            row['allocation_transfer_agency']
                if row['allocation_transfer_agency']
                else '000',
            row['agency_identifier'] if row['agency_identifier'] else '000',
            row['beginning_period_of_availa']
                if row['beginning_period_of_availa'].strip()
                else '0000',
            row['ending_period_of_availabil']
                if row['ending_period_of_availabil'].strip()
                else '0000',
            row['availability_type_code'].strip()
                if row['availability_type_code'].strip()
                else ' ',
            row['main_account_code'] if row['main_account_code'] else '0000',
            row['sub_account_code'] if row['sub_account_code'] else '000'
        ]
    );
    return tas;
}