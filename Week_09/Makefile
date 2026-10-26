SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
.RECIPEPREFIX := >

# --------------------------------------------------
# Design file
# --------------------------------------------------

DESIGN := design.csv

# Read run accessions directly from design.csv
RUNS := $(shell tail -n +2 $(DESIGN) | cut -d',' -f2)

# --------------------------------------------------
# Reference genome
# --------------------------------------------------

ASSEMBLY := GCF_000005845.2_ASM584v2

REF_URL := https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz

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

REF_GZ := $(REF_DIR)/$(ASSEMBLY)_genomic.fna.gz
REF_FASTA := $(REF_DIR)/$(ASSEMBLY)_genomic.fna
REF_INDEX := $(REF_DIR)/mg1655

# --------------------------------------------------
# Output lists
# --------------------------------------------------

BAMS := $(RUNS:%=$(ALIGN_DIR)/%_sorted.bam)
VCFS := $(RUNS:%=$(VARIANT_DIR)/%.vcf.gz)
COVERAGE_FILES := $(RUNS:%=$(STATS_DIR)/%_coverage.txt)

.SECONDARY: $(BAMS)

MERGED_VCF := $(VARIANT_DIR)/merged_multisample.vcf.gz
MERGED_STATS := $(STATS_DIR)/merged_vcf_stats.txt

# --------------------------------------------------
# Main targets
# --------------------------------------------------

.PHONY: all batch reference index check-design check-tools clean

.PHONY: all batch bams reference index check-design check-tools clean

bams: $(BAMS)

all: batch

batch: check-design check-tools $(MERGED_VCF) $(COVERAGE_FILES) $(MERGED_STATS)
> @echo
> @echo "Week 09 batch workflow complete."
> @echo "Merged VCF: $(MERGED_VCF)"
> @echo "Statistics: $(STATS_DIR)"

# --------------------------------------------------
# Validate inputs
# --------------------------------------------------

check-design:
> @test -s $(DESIGN) || { echo "ERROR: design.csv is missing or empty"; exit 1; }
> @test "$$(wc -l < $(DESIGN))" -gt 1 || { echo "ERROR: design.csv contains no samples"; exit 1; }
> @echo "Design file contains $$(($$(wc -l < $(DESIGN)) - 1)) samples."

check-tools:
> @for tool in fastq-dump fastp bowtie2 bowtie2-build samtools bcftools curl; do \
        command -v $$tool >/dev/null 2>&1 || { \
            echo "ERROR: $$tool is not available."; \
            exit 1; \
        }; \
    done
> @echo "Required tools found."

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
#
# n_spots is read from column 7 of design.csv.
# --------------------------------------------------

$(STAMP_DIR)/download_%.done: $(DESIGN)
> mkdir -p $(RAW_DIR) $(STAMP_DIR)
> N_SPOTS=$$(awk -F',' -v r="$*" 'NR>1 && $$2==r {print $$7; exit}' $(DESIGN)); \
    test -n "$$N_SPOTS" || { echo "ERROR: no n_spots value for $*"; exit 1; }; \
    echo "Downloading $* using $$N_SPOTS spots"; \
    rm -f \
        $(RAW_DIR)/$*_1.fastq.gz \
        $(RAW_DIR)/$*_2.fastq.gz \
        $(RAW_DIR)/raw_$*_R1.fastq.gz \
        $(RAW_DIR)/raw_$*_R2.fastq.gz; \
    fastq-dump \
        --split-files \
        --gzip \
        -X "$$N_SPOTS" \
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

$(STAMP_DIR)/trim_%.done: $(STAMP_DIR)/download_%.done
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
# --------------------------------------------------

$(ALIGN_DIR)/%_sorted.bam: $(STAMP_DIR)/trim_%.done $(STAMP_DIR)/index.done
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
# Coverage statistics
# --------------------------------------------------

$(STATS_DIR)/%_coverage.txt: $(ALIGN_DIR)/%_sorted.bam
> mkdir -p $(STATS_DIR)
> samtools coverage $< > $@

# --------------------------------------------------
# Call variants separately for each sample
# --------------------------------------------------

$(VARIANT_DIR)/%.vcf.gz: $(ALIGN_DIR)/%_sorted.bam $(REF_FASTA)
> mkdir -p $(VARIANT_DIR)
> bcftools mpileup \
    -Ou \
    -f $(REF_FASTA) \
    -a FORMAT/AD,FORMAT/DP \
    $< \
  | bcftools call \
    --ploidy 1 \
    -mv \
    -Oz \
    -o $@
> bcftools index -t $@

# --------------------------------------------------
# Merge all sample VCFs
# --------------------------------------------------

$(MERGED_VCF): $(VCFS)
> mkdir -p $(VARIANT_DIR)
> bcftools merge \
    --missing-to-ref \
    -Oz \
    -o $(MERGED_VCF) \
    $(VCFS)
> bcftools index -t $(MERGED_VCF)

# --------------------------------------------------
# Merged VCF statistics
# --------------------------------------------------

$(MERGED_STATS): $(MERGED_VCF) $(COVERAGE_FILES)
> mkdir -p $(STATS_DIR)
> bcftools stats $(MERGED_VCF) > $(MERGED_STATS)
> bcftools query -l $(MERGED_VCF) > $(STATS_DIR)/merged_sample_names.txt
> printf "total_variants\t" > $(STATS_DIR)/merged_variant_counts.txt
> bcftools view -H $(MERGED_VCF) | wc -l >> $(STATS_DIR)/merged_variant_counts.txt
> printf "SNPs\t" >> $(STATS_DIR)/merged_variant_counts.txt
> bcftools view -v snps -H $(MERGED_VCF) | wc -l >> $(STATS_DIR)/merged_variant_counts.txt
> printf "indels\t" >> $(STATS_DIR)/merged_variant_counts.txt
> bcftools view -v indels -H $(MERGED_VCF) | wc -l >> $(STATS_DIR)/merged_variant_counts.txt
> printf "sample\tcoverage_percent\tmean_depth\tmean_baseq\tmean_mapq\n" > $(STATS_DIR)/coverage_summary.tsv
> @for r in $(RUNS); do \
        awk -v sample="$$r" 'NR==2 {print sample "\t" $$6 "\t" $$7 "\t" $$8 "\t" $$9}' \
        $(STATS_DIR)/$${r}_coverage.txt >> $(STATS_DIR)/coverage_summary.tsv; \
    done

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
