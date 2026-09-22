"""Create a protein fasta file from features with amino acid sequences."""
def features_to_protein_fasta_file(feature_list: list[dict[str, str]], file_name: str) -> int {
    num_added = 0;
    with open(file_name, 'w') as handle {
        for feature in feature_list {
            if 'aa_sequence' in feature {
                match feature['annotation'] {
                    case 'PATRIC':
                        aa_id = 'patric_id';
                    case 'RefSeq':
                        aa_id = 'protein_id';
                    case _:
                        raise ValueError('Annotation must be either "PATRIC" or "RefSeq"');
                }
                handle.write(
                    '>{0}\n{1}\n'.format(feature[aa_id], feature['aa_sequence'])
                );
                num_added += 1;
            }
        }
    }
    return num_added;
}