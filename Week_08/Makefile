SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
.RECIPEPREFIX := >

# --------------------------------------------------
# Samples and settings
# --------------------------------------------------

RUNS := SRR001666 SRR23196710 SRR23196713
N ?= 750000

ASSEMBLY := GCF_000005845.2_ASM584v2

REF_URL := https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz

GFF_URL := https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.gff.gz

# --------------------------------------------------
# Directories
# --------------------------------------------------

REF_DIR := reference
RAW_DIR := raw_data
TRIM_DIR := trimmed_data
ALIGN_DIR := alignment
VARIANT_DIR := variants
STATS_DIR := stats
STAMP_DIR := .stamps
ANNOT_DIR := annotation

# --------------------------------------------------
# Reference
# --------------------------------------------------

REF_GZ := $(REF_DIR)/$(ASSEMBLY)_genomic.fna.gz
REF_FASTA := $(REF_DIR)/$(ASSEMBLY)_genomic.fna
REF_INDEX := $(REF_DIR)/mg1655

GFF := $(ANNOT_DIR)/$(ASSEMBLY)_genomic.gff.gz

CODING_EFFECTS := $(ANNOT_DIR)/coding_variant_effects.tsv
SELECTED_EFFECTS := $(ANNOT_DIR)/selected_variant_effects.tsv

# --------------------------------------------------
# BAM and VCF files
# --------------------------------------------------

BAMS := $(RUNS:%=$(ALIGN_DIR)/%_sorted.bam)

MULTI_VCF := $(VARIANT_DIR)/multisample_variants.vcf.gz
MULTI_VCF_INDEX := $(MULTI_VCF).tbi

# --------------------------------------------------
# Main targets
# --------------------------------------------------

.PHONY: all reference index download trim align bam-stats variants vcf-stats clean

all: bam-stats vcf-stats $(SELECTED_EFFECTS)


# --------------------------------------------------
# Reference genome
# --------------------------------------------------

reference: $(REF_FASTA)

$(REF_GZ):
> mkdir -p $(REF_DIR)
> curl -fL -o $(REF_GZ) $(REF_URL)

$(REF_FASTA): $(REF_GZ)
> gunzip -kf $(REF_GZ)
> samtools faidx $(REF_FASTA)


# --------------------------------------------------
# Bowtie2 index
# --------------------------------------------------

index: $(STAMP_DIR)/index.done

$(STAMP_DIR)/index.done: $(REF_FASTA)
> mkdir -p $(STAMP_DIR)
> bowtie2-build $(REF_FASTA) $(REF_INDEX)
> touch $@


# --------------------------------------------------
# Download reads
# --------------------------------------------------

download: $(RUNS:%=$(STAMP_DIR)/download_%_$(N).done)

$(STAMP_DIR)/download_%_$(N).done:
> mkdir -p $(RAW_DIR) $(STAMP_DIR)
> rm -f \
    $(RAW_DIR)/$*_1.fastq.gz \
    $(RAW_DIR)/$*_2.fastq.gz \
    $(RAW_DIR)/raw_$*_R1.fastq.gz \
    $(RAW_DIR)/raw_$*_R2.fastq.gz
> fastq-dump \
    --split-files \
    --gzip \
    -X $(N) \
    -O $(RAW_DIR) \
    $*
> test -f $(RAW_DIR)/$*_1.fastq.gz
> test -f $(RAW_DIR)/$*_2.fastq.gz
> mv $(RAW_DIR)/$*_1.fastq.gz $(RAW_DIR)/raw_$*_R1.fastq.gz
> mv $(RAW_DIR)/$*_2.fastq.gz $(RAW_DIR)/raw_$*_R2.fastq.gz
> touch $@


# --------------------------------------------------
# Quality filtering
# --------------------------------------------------

trim: $(RUNS:%=$(STAMP_DIR)/trim_%_$(N).done)

$(STAMP_DIR)/trim_%_$(N).done: $(STAMP_DIR)/download_%_$(N).done
> mkdir -p $(TRIM_DIR) $(STATS_DIR) $(STAMP_DIR)
> fastp \
    -i $(RAW_DIR)/raw_$*_R1.fastq.gz \
    -I $(RAW_DIR)/raw_$*_R2.fastq.gz \
    -o $(TRIM_DIR)/trimmed_$*_R1.fastq.gz \
    -O $(TRIM_DIR)/trimmed_$*_R2.fastq.gz \
    --detect_adapter_for_pe \
    --html $(STATS_DIR)/$*_fastp.html \
    --json $(STATS_DIR)/$*_fastp.json
> touch $@


# --------------------------------------------------
# Alignment
#
# Read groups are important here.
# SM identifies the sample in the multisample VCF.
# --------------------------------------------------

align: $(BAMS)

$(ALIGN_DIR)/%_sorted.bam: $(STAMP_DIR)/trim_%_$(N).done $(STAMP_DIR)/index.done
> mkdir -p $(ALIGN_DIR) $(STATS_DIR)
> bowtie2 \
    --very-sensitive \
    --rg-id $* \
    --rg SM:$* \
    -x $(REF_INDEX) \
    -1 $(TRIM_DIR)/trimmed_$*_R1.fastq.gz \
    -2 $(TRIM_DIR)/trimmed_$*_R2.fastq.gz \
    2> $(STATS_DIR)/$*_bowtie2.txt \
  | samtools sort -o $@ -
> samtools index $@


# --------------------------------------------------
# BAM statistics
# --------------------------------------------------

bam-stats: $(RUNS:%=$(STAMP_DIR)/bam_stats_%.done)

$(STAMP_DIR)/bam_stats_%.done: $(ALIGN_DIR)/%_sorted.bam
> mkdir -p $(STATS_DIR) $(STAMP_DIR)
> samtools flagstat $< > $(STATS_DIR)/$*_flagstat.txt
> samtools coverage $< > $(STATS_DIR)/$*_coverage.txt
> touch $@


# --------------------------------------------------
# Joint multisample variant calling
# --------------------------------------------------

variants: $(MULTI_VCF)

$(MULTI_VCF): $(BAMS)
> mkdir -p $(VARIANT_DIR)
> bcftools mpileup \
    -Ou \
    -f $(REF_FASTA) \
    -a FORMAT/AD,FORMAT/DP \
    $(BAMS) \
  | bcftools call \
    -mv \
    -Oz \
    -o $(MULTI_VCF)
> bcftools index -t $(MULTI_VCF)


# --------------------------------------------------
# VCF statistics
# --------------------------------------------------

vcf-stats: $(STAMP_DIR)/vcf_stats.done

$(STAMP_DIR)/vcf_stats.done: $(MULTI_VCF)
> mkdir -p $(STATS_DIR) $(STAMP_DIR)
> bcftools stats $(MULTI_VCF) > $(STATS_DIR)/multisample_vcf_stats.txt
> bcftools query -l $(MULTI_VCF) > $(STATS_DIR)/multisample_names.txt
> printf "total_variants\t" > $(STATS_DIR)/multisample_variant_counts.txt
> bcftools view -H $(MULTI_VCF) | wc -l >> $(STATS_DIR)/multisample_variant_counts.txt
> printf "SNPs\t" >> $(STATS_DIR)/multisample_variant_counts.txt
> bcftools view -v snps -H $(MULTI_VCF) | wc -l >> $(STATS_DIR)/multisample_variant_counts.txt
> printf "indels\t" >> $(STATS_DIR)/multisample_variant_counts.txt
> bcftools view -v indels -H $(MULTI_VCF) | wc -l >> $(STATS_DIR)/multisample_variant_counts.txt
> touch $@

# --------------------------------------------------
# Genome annotation
# --------------------------------------------------

$(GFF):
> mkdir -p $(ANNOT_DIR)
> curl -fL -o $(GFF) $(GFF_URL)


# --------------------------------------------------
# Predict coding variant effects
# --------------------------------------------------

$(CODING_EFFECTS): $(MULTI_VCF) $(REF_FASTA) $(GFF) scripts/annotate_coding_variants.py
> mkdir -p $(ANNOT_DIR)
> python scripts/annotate_coding_variants.py


# --------------------------------------------------
# Select variants used in the report
# --------------------------------------------------

$(SELECTED_EFFECTS): $(CODING_EFFECTS)
> awk -F'\t' 'NR==1 || $$2==25895 || $$2==44727 || $$2==214989' \
    $(CODING_EFFECTS) > $(SELECTED_EFFECTS)

# --------------------------------------------------
# Clean generated files
# --------------------------------------------------

clean:
> rm -rf \
    $(REF_DIR) \
    $(RAW_DIR) \
    $(TRIM_DIR) \
    $(ALIGN_DIR) \
    $(VARIANT_DIR) \
    $(STATS_DIR) \
    $(STAMP_DIR)