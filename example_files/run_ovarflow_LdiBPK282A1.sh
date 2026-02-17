#!/bin/bash 
#$ -adds l_hard local_free 200G
#$ -mods l_hard m_mem_free 30G
#$ -adds l_hard avx 1 
#$ -cwd
#$ -V
#$ -j y
#$ -pe smp 40
#$ -N Ovarflow_LdSQSBLA_LdiBPK282A1
#$ -o Ovarflow_LdSQSBLA_LdiBPK282A1_errors_$JOB_ID

set -e
# the experiment path
exp_path='/cluster/majf_lab/mtinti/MUT_analysis/experiments/MetaAnalysis/DataSets/LdSQSBLA/'
# we have a high performace disk space, we transfer data in dhtere for analysis, all the ovarflow input files and folders 
echo 'copy files in '$TMPDIR
cp -Lr $exp_path'ovarflow_input_LdiBPK282A1' $TMPDIR/ovarflow

echo 'run singularity'
export THREADS=40
#the input folder needs to be binded as input in singualrity
singularity run --bind $TMPDIR/ovarflow:/input /cluster/majf_lab/mtinti/MUT_analysis/experiments/OVarFlow_May10_2021_BQSR.sif

echo 'run filtering variants'
#we ran this script to fetch the variant call that are different in at least one sample
python /cluster/majf_lab/mtinti/MUT_analysis/experiments/MetaAnalysis/filter_variants.py \
$TMPDIR'/ovarflow/24_annotated_variants_2/variants_annotated.vcf.gz' \
$TMPDIR'/ovarflow/24_annotated_variants_2/ovarflow.different.annotated.vcf'

# run qualimap and multiqc on the bam aligments
run_qualimap() {
  local path="$1"
  local cores="${2:-4}"  # Default to 4 cores if not specified
  
  export path
    
  find "$path" -maxdepth 1 -name "*.bam" | parallel -j "$cores" \
    bash -c '
      if [ -f "{}" ]; then
        base=$(basename "{}" .bam)
        qualimap bamqc --java-mem-size=4G -bam "{}" \
          -outdir "$path/qualimap_bam/$base/" \
          -outformat "HTML"
      fi 
    '
    multiqc "$path/qualimap_bam/" -o "$path/qualimap_bam/"
}

run_qualimap $TMPDIR/ovarflow/03_mark_duplicates "$THREADS"



echo 'copy results'
mkdir -p $exp_path'res_LdiBPK282A1/ovarflow_res'

cp -r $TMPDIR/ovarflow/24_annotated_variants_2 $exp_path'res_LdiBPK282A1/ovarflow_res'

cp -r $TMPDIR/ovarflow/03_mark_duplicates $exp_path'res_LdiBPK282A1/ovarflow_res'

cp -r $TMPDIR/ovarflow/snpEffDB $exp_path'res_LdiBPK282A1/ovarflow_res'



