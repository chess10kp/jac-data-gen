"""Use htseq-count for quantification."""
def htseq_quant(curr_sample: str, out_dir: str, ERCC_gtf: str, strand: str) -> str {
    cmd = "";
    cmd = cmd + "mkdir " + out_dir + "htseq_out/\n";
    if strand == "nonstrand" {
        cmd = cmd + "samtools view " + curr_sample + "_accepted_hits.sorted.bam | htseq-count -r pos --stranded=no - " + ERCC_gtf + " > " + out_dir + "htseq_out/" + curr_sample + "_counts.txt\n";
    } elif strand == "reverse" {
        cmd = cmd + "samtools view " + curr_sample + "_accepted_hits.sorted.bam | htseq-count -r pos --stranded=reverse - " + ERCC_gtf + " > " + out_dir + "htseq_out/" + curr_sample + "_counts.txt\n";
    } elif strand == "forward" {
        cmd = cmd + "samtools view " + curr_sample + "_accepted_hits.sorted.bam | htseq-count -r pos --stranded=yes - " + ERCC_gtf + " > " + out_dir + "htseq_out/" + curr_sample + "_counts.txt\n";
    }
    return cmd;
}