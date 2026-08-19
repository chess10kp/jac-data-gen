bits_set = 0;
while flags > 0 {
    bits_set += flags & 1;
    flags >>= 1;
}
