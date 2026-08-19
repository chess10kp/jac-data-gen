glob count = 0;
glob bump = lambda : (count := count + 1);

with entry {
    bump();
    print(count);   # 1
}
