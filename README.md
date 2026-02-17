# OVarFlow_instructions


## Reference to read
- https://ovarflow.readthedocs.io/en/latest/UsageOfOVarFlow/CondaSnakemake.html#what-are-read-groups
- https://ovarflow.readthedocs.io/en/latest/UsageOfOVarFlow/CondaSnakemake.html#the-csv-configuration-file
- https://ovarflow.readthedocs.io/en/latest/UsageOfOVarFlow/CondaSnakemake.html#starting-the-workflow


- https://ovarflow.readthedocs.io/en/latest/UsageOfOVarFlow/Configuration.html

## Make .gz example 

```
seqkit sort -n \
REFERENCE_INPUT_DIR_SylvioX10-1/TriTrypDB-68_TcruziSylvioX10-1_Genome.fasta \
> REFERENCE_INPUT_DIR_SylvioX10-1/TriTrypDB-68_TcruziSylvioX10-1_Genome.sorted.fasta

gzip -c REFERENCE_INPUT_DIR_SylvioX10-1/TriTrypDB-68_TcruziSylvioX10-1_Genome.sorted.fasta > \
REFERENCE_INPUT_DIR_SylvioX10-1/SW_SylvioX10-1.fa.gz

/cluster/majf_lab/mtinti/RNAseq/viper-test/genomes/gff3sort/gff3sort.pl --precise --chr_order natural \
REFERENCE_INPUT_DIR_SylvioX10-1/TriTrypDB-68_TcruziSylvioX10-1.gff \
> REFERENCE_INPUT_DIR_SylvioX10-1/TriTrypDB-68_TcruziSylvioX10-1.sorted.gff

cp REFERENCE_INPUT_DIR_SylvioX10-1/TriTrypDB-68_TcruziSylvioX10-1.sorted.gff \
REFERENCE_INPUT_DIR_SylvioX10-1/SW_SylvioX10-1.sorted.gff
```


## input folder structure
```
INPUT DIR (ovarflow_input_LdiBPK282A1 in cluster example)
|-FASTQ_INPUT_DIR
|-OLD_GVCF_FILES
|-REFERENCE_INPUT_DIR
|-samples_and_read_groups.csv
```

## example of samples_and_read_groups.csv

```
Reference Sequence:,SW_SylvioX10-1.fa.gz
Reference Annotation:,SW_SylvioX10-1.sorted.gff

Min sequence length:,2000

old gvcf to include:,

forward reads,reverse reads,ID,PL - plattform technology,CN - sequencing center,LB - library name,SM - uniq sample name
V350357015_L02_B5GANIokjbRAAGA-30_R1.fastq.gz,V350357015_L02_B5GANIokjbRAAGA-30_R2.fastq.gz,id_TcCRK12_dKOdd1,illumina,ENA,lib_TcCRK12_dKOdd1,TcCRK12_dKOdd1
V350357015_L02_B5GANIokjbRAAHA-114_R1.fastq.gz,V350357015_L02_B5GANIokjbRAAHA-114_R2.fastq.gz,id_TcCRK12BirA5C6,illumina,ENA,lib_TcCRK12BirA5C6,TcCRK12BirA5C6
```

## Logic

ovarflow then expect expect 
V350357015_L02_B5GANIokjbRAAGA-30_R1.fastq.gz
V350357015_L02_B5GANIokjbRAAGA-30_R2.fastq.gz
V350357015_L02_B5GANIokjbRAAHA-114_R1.fastq.gz
V350357015_L02_B5GANIokjbRAAHA-114_R2.fastq.gz
in FASTQ_INPUT_DIR


You can keep  OLD_GVCF_FILES empty, I never tried to put in there old variant calls

REFERENCE_INPUT_DIR
SW_SylvioX10-1.fa.gz (sorted gzipped)
SW_SylvioX10-1.sorted.gff (sorted) can be gzipped as well, it works without gzip
used gff3sort.pl at https://github.com/tao-bioinfo/gff3sort/tree/master for sorting, might not be necessary


## miscellaneous and utility script, not strictly necessary

- BGI sometimes output multiple fastq pairs for the sampe sample, those need to be merged togheter using this utility script
merge_fastq.sh


- ovarflow wants the file name of fastq fiiles ending _R1.fastq.gz and _R2.fastq.gz rename was done with this script

```python
import os
import re
#GOOD ONE
def rename_fastq_files(root_dir):
    # Compile regex patterns for matching file names
    pattern1 = re.compile(r'(.*)_1\.fq\.gz$')
    pattern2 = re.compile(r'(.*)_2\.fq\.gz$')

    # Walk through all subdirectories
    for dirpath, dirnames, filenames in os.walk(root_dir):
        for filename in filenames:
            
            # Check if the file matches the first pattern
            match1 = pattern1.match(filename)
            if match1:
                old_name = os.path.join(dirpath, filename)
                new_name = os.path.join(dirpath, f"{match1.group(1)}_R1.fastq.gz")
                os.rename(old_name, new_name)
                print(f"Renamed: {old_name} -> {new_name}")
            
            # Check if the file matches the second pattern
            match2 = pattern2.match(filename)
            if match2:
                old_name = os.path.join(dirpath, filename)
                new_name = os.path.join(dirpath, f"{match2.group(1)}_R2.fastq.gz")
                os.rename(old_name, new_name)
                print(f"Renamed: {old_name} -> {new_name}")

#Usage
root_directory = "/cluster/majf_lab/mtinti/MUT_analysis/experiments/MetaAnalysis/DataSets/LdSQSBLA/"
rename_fastq_files(root_directory)
```


- this utility create a sample list starting from a folder with the samples/fastq pair organization. the output can be copy pasted in samples_and_read_groups.csv
below the forward reads,reverse... reads,ID,PL headers

```python
import os
import re

def parse_fastq_pairs(root_dir):
    # Compile regex patterns for matching file names
    pattern1 = re.compile(r'(.*)_R1\.fastq\.gz$')
    pattern2 = re.compile(r'(.*)_R2\.fastq\.gz$')

    # Walk through all subdirectories
    for dirpath, dirnames, filenames in os.walk(root_dir):
        # Get the folder name and replace dots and hyphens with underscores
        folder_name = os.path.basename(dirpath).replace('.', '_').replace('-', '_')
        
        # Dictionary to store fastq pairs
        fastq_pairs = {}

        # Find all fastq files and pair them
        for filename in filenames:
            match1 = pattern1.match(filename)
            match2 = pattern2.match(filename)
            
            if match1:
                base_name = match1.group(1)
                if base_name not in fastq_pairs:
                    fastq_pairs[base_name] = {'R1': filename}
                else:
                    fastq_pairs[base_name]['R1'] = filename
            elif match2:
                base_name = match2.group(1)
                if base_name not in fastq_pairs:
                    fastq_pairs[base_name] = {'R2': filename}
                else:
                    fastq_pairs[base_name]['R2'] = filename

        # Print information for complete pairs
        for base_name, files in fastq_pairs.items():
            if 'R1' in files and 'R2' in files:
                print(f"{files['R1']},{files['R2']},id_{folder_name},illumina,ENA,lib_{folder_name},{folder_name}")



#root_directory = "/cluster/majf_lab/mtinti/MUT_analysis/experiments/MetaAnalysisTrypCruzi/DataSets/TcCRK12/"
parse_fastq_pairs(root_directory)
```

- finally the files were symlinked to the FASTQ_INPUT_DIR folder
```python
import os
import re

def create_fastq_symlinks(source_dir):
    # Compile regex patterns for matching file names
    pattern1 = re.compile(r'(.*)_R1\.fastq\.gz$')
    pattern2 = re.compile(r'(.*)_R2\.fastq\.gz$')

    # Create FASTQ_INPUT_DIR at the same level as source_dir
    parent_dir = os.path.dirname(source_dir)
    fastq_input_dir = os.path.join(source_dir, 'FASTQ_INPUT_DIR')
    os.makedirs(fastq_input_dir, exist_ok=True)

    # Walk through all subdirectories
    for dirpath, dirnames, filenames in os.walk(source_dir):
        # Dictionary to store fastq pairs
        fastq_pairs = {}

        # Find all fastq files and pair them
        for filename in filenames:
            match1 = pattern1.match(filename)
            match2 = pattern2.match(filename)
            
            if match1:
                base_name = match1.group(1)
                if base_name not in fastq_pairs:
                    fastq_pairs[base_name] = {'R1': filename}
                else:
                    fastq_pairs[base_name]['R1'] = filename
            elif match2:
                base_name = match2.group(1)
                if base_name not in fastq_pairs:
                    fastq_pairs[base_name] = {'R2': filename}
                else:
                    fastq_pairs[base_name]['R2'] = filename

        # Create symlinks for complete pairs
        for base_name, files in fastq_pairs.items():
            if 'R1' in files and 'R2' in files:
                for read in ['R1', 'R2']:
                    source_file = os.path.join(dirpath, files[read])
                    link_name = os.path.join(fastq_input_dir, files[read])
                    
                    # Create symlink
                    if not os.path.exists(link_name):
                        os.symlink(source_file, link_name)
                        print(f"Created symlink: {link_name} -> {source_file}")
                    else:
                        print(f"Symlink already exists: {link_name}")

# Usage
source_directory = root_directory#"/cluster/majf_lab/mtinti/MUT_analysis/experiments/MetaAnalysisTrypBrucei/DataSets/TbYBA/"
create_fastq_symlinks(source_directory)
```

