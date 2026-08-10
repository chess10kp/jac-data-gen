"""
cov = number of bases / length of genome
relative abundance = [(cov) / sum(cov for all genomes)] * 100
"""
def relative_abundance(coverage: dict[str, list[float]]) -> dict[str, list[float | int]] {
    relative = {};
    sums: list[float] = [];
    for genome in coverage {
        for cov in coverage[genome] {
            sums.append(0);
        }
        break;
    }
    for genome in coverage {
        index = 0;
        for cov in coverage[genome] {
            sums[index] += cov;
            index += 1;
        }
    }
    for genome in coverage {
        index = 0;
        relative[genome] = [];
        for cov in coverage[genome] {
            if sums[index] == 0 {
                relative[genome].append(0);
            } else {
                relative[genome].append((cov / sums[index]) * float(100));
            }
            index += 1;
        }
    }
    return relative;
}