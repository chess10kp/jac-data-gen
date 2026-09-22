"""Keep chromosomes that are a digit 1-22, or chr prefixed digit chr1-chr22
    """
def is_autosomal(chrom: Any) -> object {
    try {
        int(chrom);
        return True;
    } except ValueError {
        try {
            int(
                str(chrom.lower().replace("chr", "").replace("_", "").replace("-", ""))
            );
            return True;
        } except ValueError {
            return False;
        }
    }
}