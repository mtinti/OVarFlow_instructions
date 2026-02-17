import sys
import pysam
from tqdm.auto import tqdm

if len(sys.argv) != 3:
    print("Usage: python filter_variants.py <input_vcf> <output_vcf>")
    sys.exit(1)

infile = sys.argv[1]
outfile = sys.argv[2]

# Determine if the input VCF file is gzipped
if infile.endswith('.gz'):
    vcf_in = pysam.VariantFile(infile, 'r')
else:
    vcf_in = pysam.VariantFile(infile)

vcf_out = pysam.VariantFile(outfile, 'w', header=vcf_in.header)

for variant in tqdm(vcf_in):
    genotypes = []
    for sample in variant.samples:
        genotype = variant.samples[sample]['GT']
        genotypes.append(genotype)
    if len(variant.samples)==1:
        vcf_out.write(variant)
        
    if len(set(genotypes)) > 1:
        vcf_out.write(variant)

vcf_in.close()
vcf_out.close()
