# OVarFlow – How to Run on the Cluster

## 1. Input folder structure

Create a single input directory (name it however you like, e.g. `ovarflow_input_MyExp`) containing exactly three sub-folders and the CSV config file:

```
ovarflow_input_MyExp/
├── FASTQ_INPUT_DIR/               # paired-end FASTQ files
├── OLD_GVCF_FILES/                # leave empty if not reusing old calls
├── REFERENCE_INPUT_DIR/           # reference genome + annotation
└── samples_and_read_groups.csv
```

---

## 2. Prepare the reference genome

Place in `REFERENCE_INPUT_DIR/` a **gzipped FASTA** and a **GFF** file.
Both files must share the same basename, which is also what you will put in the CSV (see below).

```
REFERENCE_INPUT_DIR/{genome}.fa.gz
REFERENCE_INPUT_DIR/{genome}.sorted.gff
```

The FASTA must be gzipped:

```bash
gzip -c genome.fasta > REFERENCE_INPUT_DIR/{genome}.fa.gz
```

Replace `{genome}` with a short descriptive name, e.g. `SW_LdonovaniBPK282A1`.

---

## 3. Prepare the FASTQ files

OVarFlow expects paired files named **exactly**:

```
<sample>_R1.fastq.gz
<sample>_R2.fastq.gz
```

Rename your files to match this convention before placing them in `FASTQ_INPUT_DIR/`.

---

## 4. The sample CSV file

`samples_and_read_groups.csv` lives directly inside the input folder.
Edit the template below – **do not change the row/column order**.

```csv
Reference Sequence:,{genome}.fa.gz
Reference Annotation:,{genome}.sorted.gff

Min sequence length:,2000

old gvcf to include:,

forward reads,reverse reads,ID,PL - plattform technology,CN - sequencing center,LB - library name,SM - uniq sample name
Sample1_R1.fastq.gz,Sample1_R2.fastq.gz,id_Sample1,illumina,ENA,lib_Sample1,Sample1
Sample2_R1.fastq.gz,Sample2_R2.fastq.gz,id_Sample2,illumina,ENA,lib_Sample2,Sample2
```

- `{genome}` must match the filenames you created in step 2.
- `SM` (last column) must be unique per sample and kept short.
- Leave `old gvcf to include:` empty if you have no prior calls to merge.

---

## 5. Submit the job

Use `run_ovarflow.sh` (see the script in this folder).
Set the one variable at the top of the script and submit:

```bash
# Edit this line in run_ovarflow.sh:
input_path='/path/to/ovarflow_input_MyExp'

qsub run_ovarflow.sh
```

Results are copied back into `ovarflow_res/` inside the input folder:
- `24_annotated_variants_2/` – annotated VCFs
- `03_mark_duplicates/` – deduplicated BAMs
- `snpEffDB/` – snpEff annotation database
