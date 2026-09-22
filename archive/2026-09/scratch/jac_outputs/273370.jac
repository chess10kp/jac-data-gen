""" https://wiki.guildwars2.com/wiki/Exquisite_Extract_of_Nourishment """
def calc_price_exquisite_extract_of_nourishment(
    fine_price: int, masterwork_price: int, rare_price: int, exotic_price: int
) -> int {
    return 5 * fine_price + 5 * masterwork_price + 5 * rare_price + 10 * exotic_price;
}