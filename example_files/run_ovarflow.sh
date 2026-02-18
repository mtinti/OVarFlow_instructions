#!/bin/bash
#$ -adds l_hard local_free 200G
#$ -mods l_hard m_mem_free 30G
#$ -adds l_hard avx 1
#$ -cwd
#$ -V
#$ -j y
#$ -pe smp 40
#$ -N Ovarflow
#$ -o Ovarflow_errors_$JOB_ID

set -e

# ── USER SETTINGS ─────────────────────────────────────────────────────────────
# Full path to the OVarFlow input folder.
# Can be passed as the first argument: qsub run_ovarflow.sh /path/to/input
# If not provided, the hardcoded value below is used.
input_path="${1:-/cluster/majf_lab/mtinti/MUT_analysis/experiments/MyExperiment/ovarflow_input_MyExp}"
# ──────────────────────────────────────────────────────────────────────────────

# ── FIXED SETTINGS (do not change) ───────────────────────────────────────────
SIF='/cluster/majf_lab/mtinti/MUT_analysis/experiments/OVarFlow_May10_2021_BQSR.sif'
export THREADS=40
# ──────────────────────────────────────────────────────────────────────────────

echo "copy input to TMPDIR"
cp -Lr "$input_path" "$TMPDIR/ovarflow"

echo "run OVarFlow via Singularity"
singularity run --bind "$TMPDIR/ovarflow:/input" "$SIF"

echo "copy results back"
mkdir -p "$input_path/ovarflow_res"

cp -r "$TMPDIR/ovarflow/24_annotated_variants_2" "$input_path/ovarflow_res"
cp -r "$TMPDIR/ovarflow/03_mark_duplicates"       "$input_path/ovarflow_res"
cp -r "$TMPDIR/ovarflow/snpEffDB"                 "$input_path/ovarflow_res"

echo "done"
