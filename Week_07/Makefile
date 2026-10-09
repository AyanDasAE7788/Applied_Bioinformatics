SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
.RECIPEPREFIX := >

# --------------------------------------------------
# User settings
# --------------------------------------------------

SRR ?= SRR001666
N ?= 750000

# E. coli K-12 MG1655 reference genome
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

# --------------------------------------------------
# Reference files
# --------------------------------------------------

REF_GZ := $(REF_DIR)/$(ASSEMBLY)_genomic.fna.gz
REF_FASTA := $(REF_DIR)/$(ASSEMBLY)_genomic.fna
REF_INDEX := $(REF_DIR)/mg1655

# --------------------------------------------------
# BAM files
# --------------------------------------------------

BAM := $(ALIGN_DIR)/$(SRR)_sorted.bam
BAI := $(BAM).bai

# --------------------------------------------------
# VCF files
# --------------------------------------------------

VCF := $(VARIANT_DIR)/$(SRR)_variants.vcf.gz
VCF_INDEX := $(VCF).tbi

# --------------------------------------------------
# Stamp files
# --------------------------------------------------

INDEX_STAMP := $(STAMP_DIR)/index.done
DOWNLOAD_STAMP := $(STAMP_DIR)/download_$(SRR)_$(N).done
TRIM_STAMP := $(STAMP_DIR)/trim_$(SRR)_$(N).done
ALIGN_STAMP := $(STAMP_DIR)/align_$(SRR)_$(N).done
BAM_REPORT_STAMP := $(STAMP_DIR)/bam_report_$(SRR)_$(N).done
CALL_STAMP := $(STAMP_DIR)/call_$(SRR)_$(N).done
VCF_REPORT_STAMP := $(STAMP_DIR)/vcf_report_$(SRR)_$(N).done

# --------------------------------------------------
# Main targets
# --------------------------------------------------

.PHONY: all reference index download trim align bam-report callvariants vcf-report clean

all: vcf-report


# --------------------------------------------------
# Reference genome
# --------------------------------------------------

reference: $(REF_FASTA)

$(REF_GZ):
> mkdir -p $(REF_DIR)
> curl -fL \
    -o $(REF_GZ) \
    $(REF_URL)

$(REF_FASTA): $(REF_GZ)
> gunzip -kf $(REF_GZ)
> samtools faidx $(REF_FASTA)


# --------------------------------------------------
# Bowtie2 index
# --------------------------------------------------

index: $(INDEX_STAMP)

$(INDEX_STAMP): $(REF_FASTA)
> mkdir -p $(STAMP_DIR)
> bowtie2-build $(REF_FASTA) $(REF_INDEX)
> touch $(INDEX_STAMP)


# --------------------------------------------------
# Download SRA reads
# --------------------------------------------------

download: $(DOWNLOAD_STAMP)

$(DOWNLOAD_STAMP):
> mkdir -p $(RAW_DIR) $(STAMP_DIR)
> @command -v fastq-dump >/dev/null 2>&1 || { echo "ERROR: fastq-dump not found."; exit 1; }
> rm -f \
    $(RAW_DIR)/$(SRR).fastq.gz \
    $(RAW_DIR)/$(SRR)_1.fastq.gz \
    $(RAW_DIR)/$(SRR)_2.fastq.gz \
    $(RAW_DIR)/raw_$(SRR).fastq.gz \
    $(RAW_DIR)/raw_$(SRR)_R1.fastq.gz \
    $(RAW_DIR)/raw_$(SRR)_R2.fastq.gz
> fastq-dump \
    --split-files \
    --gzip \
    -X $(N) \
    -O $(RAW_DIR) \
    $(SRR)
> @if [ -f "$(RAW_DIR)/$(SRR)_2.fastq.gz" ]; then \
    mv "$(RAW_DIR)/$(SRR)_1.fastq.gz" "$(RAW_DIR)/raw_$(SRR)_R1.fastq.gz"; \
    mv "$(RAW_DIR)/$(SRR)_2.fastq.gz" "$(RAW_DIR)/raw_$(SRR)_R2.fastq.gz"; \
  elif [ -f "$(RAW_DIR)/$(SRR)_1.fastq.gz" ]; then \
    mv "$(RAW_DIR)/$(SRR)_1.fastq.gz" "$(RAW_DIR)/raw_$(SRR).fastq.gz"; \
  elif [ -f "$(RAW_DIR)/$(SRR).fastq.gz" ]; then \
    mv "$(RAW_DIR)/$(SRR).fastq.gz" "$(RAW_DIR)/raw_$(SRR).fastq.gz"; \
  else \
    echo "ERROR: FASTQ files were not generated."; \
    exit 1; \
  fi
> touch $(DOWNLOAD_STAMP)


# --------------------------------------------------
# Quality filtering
# --------------------------------------------------

trim: $(TRIM_STAMP)

$(TRIM_STAMP): $(DOWNLOAD_STAMP)
> mkdir -p $(TRIM_DIR) $(STATS_DIR) $(STAMP_DIR)
> @command -v fastp >/dev/null 2>&1 || { echo "ERROR: fastp not found."; exit 1; }
> rm -f $(TRIM_DIR)/trimmed_$(SRR)*
> @if [ -f "$(RAW_DIR)/raw_$(SRR)_R2.fastq.gz" ]; then \
    fastp \
      -i $(RAW_DIR)/raw_$(SRR)_R1.fastq.gz \
      -I $(RAW_DIR)/raw_$(SRR)_R2.fastq.gz \
      -o $(TRIM_DIR)/trimmed_$(SRR)_R1.fastq.gz \
      -O $(TRIM_DIR)/trimmed_$(SRR)_R2.fastq.gz \
      --detect_adapter_for_pe \
      --html $(STATS_DIR)/$(SRR)_fastp.html \
      --json $(STATS_DIR)/$(SRR)_fastp.json; \
  else \
    fastp \
      -i $(RAW_DIR)/raw_$(SRR).fastq.gz \
      -o $(TRIM_DIR)/trimmed_$(SRR).fastq.gz \
      --html $(STATS_DIR)/$(SRR)_fastp.html \
      --json $(STATS_DIR)/$(SRR)_fastp.json; \
  fi
> touch $(TRIM_STAMP)


# --------------------------------------------------
# Alignment and BAM creation
# --------------------------------------------------

align: $(ALIGN_STAMP)

$(ALIGN_STAMP): $(TRIM_STAMP) $(INDEX_STAMP)
> mkdir -p $(ALIGN_DIR) $(STATS_DIR) $(STAMP_DIR)
> rm -f $(BAM) $(BAI)
> @if [ -f "$(TRIM_DIR)/trimmed_$(SRR)_R2.fastq.gz" ]; then \
    bowtie2 \
      --very-sensitive \
      -x $(REF_INDEX) \
      -1 $(TRIM_DIR)/trimmed_$(SRR)_R1.fastq.gz \
      -2 $(TRIM_DIR)/trimmed_$(SRR)_R2.fastq.gz \
      2> $(STATS_DIR)/$(SRR)_bowtie2.txt \
    | samtools sort -o $(BAM) -; \
  else \
    bowtie2 \
      --very-sensitive \
      -x $(REF_INDEX) \
      -U $(TRIM_DIR)/trimmed_$(SRR).fastq.gz \
      2> $(STATS_DIR)/$(SRR)_bowtie2.txt \
    | samtools sort -o $(BAM) -; \
  fi
> samtools index $(BAM)
> touch $(ALIGN_STAMP)


# --------------------------------------------------
# BAM statistics
# --------------------------------------------------

bam-report: $(BAM_REPORT_STAMP)

$(BAM_REPORT_STAMP): $(ALIGN_STAMP)
> mkdir -p $(STATS_DIR) $(STAMP_DIR)
> samtools flagstat $(BAM) > $(STATS_DIR)/$(SRR)_flagstat.txt
> samtools stats $(BAM) > $(STATS_DIR)/$(SRR)_samtools_stats.txt
> samtools coverage $(BAM) > $(STATS_DIR)/$(SRR)_coverage.txt
> touch $(BAM_REPORT_STAMP)


# --------------------------------------------------
# Variant calling
# --------------------------------------------------

callvariants: $(CALL_STAMP)

$(CALL_STAMP): $(BAM_REPORT_STAMP)
> mkdir -p $(VARIANT_DIR) $(STATS_DIR) $(STAMP_DIR)
> @command -v bcftools >/dev/null 2>&1 || { echo "ERROR: bcftools not found."; exit 1; }
> rm -f $(VCF) $(VCF_INDEX)
> bcftools mpileup \
    -Ou \
    -f $(REF_FASTA) \
    -a FORMAT/AD,FORMAT/DP \
    $(BAM) \
  | bcftools call \
    -mv \
    -Oz \
    -o $(VCF)
> bcftools index -t $(VCF)
> touch $(CALL_STAMP)


# --------------------------------------------------
# VCF statistics
# --------------------------------------------------

vcf-report: $(VCF_REPORT_STAMP)

$(VCF_REPORT_STAMP): $(CALL_STAMP)
> mkdir -p $(STATS_DIR) $(STAMP_DIR)
> bcftools stats $(VCF) > $(STATS_DIR)/$(SRR)_vcf_stats.txt
> printf "total_variants\t" > $(STATS_DIR)/$(SRR)_variant_counts.txt
> bcftools view -H $(VCF) | wc -l >> $(STATS_DIR)/$(SRR)_variant_counts.txt
> printf "SNPs\t" >> $(STATS_DIR)/$(SRR)_variant_counts.txt
> bcftools view -v snps -H $(VCF) | wc -l >> $(STATS_DIR)/$(SRR)_variant_counts.txt
> printf "indels\t" >> $(STATS_DIR)/$(SRR)_variant_counts.txt
> bcftools view -v indels -H $(VCF) | wc -l >> $(STATS_DIR)/$(SRR)_variant_counts.txt
> printf "CHROM\tPOS\tREF\tALT\tQUAL\tDP\n" > $(STATS_DIR)/$(SRR)_variant_table.tsv
> bcftools query \
    -f '%CHROM\t%POS\t%REF\t%ALT\t%QUAL\t%INFO/DP\n' \
    $(VCF) >> $(STATS_DIR)/$(SRR)_variant_table.tsv
> touch $(VCF_REPORT_STAMP)


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