def fizzbuzz(n: int) -> str {
        if n % 15 == 0 { return "FizzBuzz"; }
        elif n % 3 == 0 { return "Fizz"; }
        elif n % 5 == 0 { return "Buzz"; }
        return str(n);
    }

    def countdown(n: int) -> Generator[int] {
        while n > 0 {
            yield n;
            n -= 1;
        }
    }

    with entry {
        results = [fizzbuzz(i) for i in range(1, 16)];
        print(results);
        print([x for x in countdown(5)]);
    }
