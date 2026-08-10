glob SECTION_BYTE_FILL = 0xFF;

"""Create a block of data to represend a section

	Creates a list of the given size and returns it. The list will have every
	byte set to 0xff. This is because reserved bits are normally set to 1
	Arguments:
		data_length -- amount of bytes needed for the data block
	Returns:
		A list of bytes of the desired length with zero in every byte
	"""
def create_section_data_block(data_length: int) -> list[int] {
    return [SECTION_BYTE_FILL] * data_length;
}