"""Returns contents of SLURM script for a gpu job."""
def get_slurm_script_gpu(output_dir: str, command: str) -> str {
    return """#!/bin/bash
#SBATCH -N 1
#SBATCH --ntasks-per-node=1
#SBATCH --ntasks-per-socket=1
#SBATCH --gres=gpu:tesla_v100:1
#SBATCH --cpus-per-task=8
#SBATCH --mem=256000
#SBATCH --output={}/slurm_%j.out
#SBATCH -t 24:00:00
#module load anaconda3 cudatoolkit/10.0 cudnn/cuda-10.0/7.3.1
#source activate yumi
{}
""".format(
        output_dir, command
    );
}