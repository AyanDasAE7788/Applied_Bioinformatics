SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
.SECONDARY:
.RECIPEPREFIX := >

DESIGN := design.csv

# Samples are read directly from the design file
SAMPLES := $(shell tail -n +2 $(DESIGN) | cut -d',' -f1)
CHIP_SAMPLES := $(shell awk -F',' 'NR>1 && $$6=="chip" {print $$1}' $(DESIGN))
INPUT_SAMPLES := $(shell awk -F',' 'NR>1 && $$6=="input" {print $$1}' $(DESIGN))

# Reference genome
ASSEMBLY := GCF_000005845.2_ASM584v2
REF_URL := https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/GCF_000005845.2_ASM584v2/GCF_000005845.2_ASM584v2_genomic.fna.gz

REF_DIR := reference
RAW_DIR := raw_data
TRIM_DIR := trimmed_data
ALIGN_DIR := alignment
COV_DIR := coverage
PEAK_DIR := peaks
COMPARE_DIR := comparisons
STATS_DIR := stats
STAMP_DIR := .stamps

REF_GZ := $(REF_DIR)/$(ASSEMBLY)_genomic.fna.gz
REF_FASTA := $(REF_DIR)/$(ASSEMBLY)_genomic.fna
REF_INDEX := $(REF_DIR)/mg1655

BAMS := $(SAMPLES:%=$(ALIGN_DIR)/%_sorted.bam)
COVERAGE_FILES := $(SAMPLES:%=$(COV_DIR)/%.bedgraph)
PEAK_FILES := $(CHIP_SAMPLES:%=$(PEAK_DIR)/%_peaks.broadPeak)

.PHONY: all batch check-design check-tools reference index \
        background chips coverage peaks compare clean

all: batch

batch: check-design check-tools coverage peaks compare
> @echo
> @echo "Week 10 ChIP-seq workflow complete."
> @echo "Coverage tracks: $(COV_DIR)"
> @echo "Peak calls: $(PEAK_DIR)"
> @echo "Replicate comparisons: $(COMPARE_DIR)"

# --------------------------------------------------
# Validation
# --------------------------------------------------

check-design:
> @test -s $(DESIGN) || { echo "ERROR: design.csv is missing."; exit 1; }
> @echo "Samples: $$(($$(wc -l < $(DESIGN)) - 1))"
> @echo "ChIP samples: $$(awk -F',' 'NR>1 && $$6=="chip"' $(DESIGN) | wc -l)"
> @echo "Input samples: $$(awk -F',' 'NR>1 && $$6=="input"' $(DESIGN) | wc -l)"

check-tools:
> @for tool in fastq-dump fastp bowtie2 bowtie2-build samtools bedtools macs3 curl; do \
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
> curl -fL -o $@ $(REF_URL)

$(REF_FASTA): $(REF_GZ)
> gunzip -kf $(REF_GZ)
> samtools faidx $@

index: $(STAMP_DIR)/index.done

$(STAMP_DIR)/index.done: $(REF_FASTA)
> mkdir -p $(STAMP_DIR)
> bowtie2-build $(REF_FASTA) $(REF_INDEX)
> touch $@

# --------------------------------------------------
# Download single-end reads
# --------------------------------------------------

$(RAW_DIR)/%.fastq.gz: $(DESIGN)
> mkdir -p $(RAW_DIR)
> RUN=$$(awk -F',' -v s="$*" 'NR>1 && $$1==s {print $$2; exit}' $(DESIGN)); \
    N=$$(awk -F',' -v s="$*" 'NR>1 && $$1==s {print $$8; exit}' $(DESIGN)); \
    test -n "$$RUN" || { echo "ERROR: no run found for $*"; exit 1; }; \
    test -n "$$N" || { echo "ERROR: no n_spots found for $*"; exit 1; }; \
    echo "Downloading $* ($$RUN), $$N reads"; \
    fastq-dump \
        --gzip \
        -X "$$N" \
        -O $(RAW_DIR) \
        "$$RUN"; \
    mv "$(RAW_DIR)/$${RUN}.fastq.gz" "$@"

# --------------------------------------------------
# Quality filtering
# --------------------------------------------------

$(TRIM_DIR)/%.fastq.gz: $(RAW_DIR)/%.fastq.gz
> mkdir -p $(TRIM_DIR) $(STATS_DIR)
> fastp \
    -i $< \
    -o $@ \
    --html $(STATS_DIR)/$*_fastp.html \
    --json $(STATS_DIR)/$*_fastp.json

# --------------------------------------------------
# Alignment
# --------------------------------------------------

$(ALIGN_DIR)/%_sorted.bam: $(TRIM_DIR)/%.fastq.gz $(STAMP_DIR)/index.done
> mkdir -p $(ALIGN_DIR) $(STATS_DIR)
> bowtie2 \
    --very-sensitive \
    --rg-id $* \
    --rg SM:$* \
    -x $(REF_INDEX) \
    -U $< \
    2> $(STATS_DIR)/$*_bowtie2.txt \
  | samtools sort -o $@ -
> samtools index $@
> samtools flagstat $@ > $(STATS_DIR)/$*_flagstat.txt

background: $(INPUT_SAMPLES:%=$(ALIGN_DIR)/%_sorted.bam)

chips: $(CHIP_SAMPLES:%=$(ALIGN_DIR)/%_sorted.bam)

# --------------------------------------------------
# Coverage tracks for IGV
# RPM-normalized bedGraph
# --------------------------------------------------

$(COV_DIR)/%.bedgraph: $(ALIGN_DIR)/%_sorted.bam
> mkdir -p $(COV_DIR)
> MAPPED=$$(samtools view -c -F 260 $<); \
    test "$$MAPPED" -gt 0 || { echo "ERROR: no mapped reads in $<"; exit 1; }; \
    SCALE=$$(awk -v n="$$MAPPED" 'BEGIN {print 1000000/n}'); \
    bedtools genomecov \
        -ibam $< \
        -bg \
        -scale "$$SCALE" \
        > $@

coverage: $(COVERAGE_FILES)

# --------------------------------------------------
# MACS3 peak calling
#
# H-NS often occupies extended genomic regions, so
# broad peak calling is used.
# --------------------------------------------------

$(PEAK_DIR)/%_peaks.broadPeak: $(ALIGN_DIR)/%_sorted.bam $(BAMS) $(DESIGN)
> mkdir -p $(PEAK_DIR)
> CONTROL=$$(awk -F',' -v s="$*" 'NR>1 && $$1==s {print $$7; exit}' $(DESIGN)); \
    test -n "$$CONTROL" || { echo "ERROR: no control listed for $*"; exit 1; }; \
    echo "Calling peaks for $* using control $$CONTROL"; \
    macs3 callpeak \
        -t $(ALIGN_DIR)/$*_sorted.bam \
        -c $(ALIGN_DIR)/$${CONTROL}_sorted.bam \
        -f BAM \
        -g 4641652 \
        -n $* \
        --outdir $(PEAK_DIR) \
        --broad \
        --nomodel \
        --extsize 200 \
        --keep-dup all \
        -q 0.05

peaks: $(PEAK_FILES) $(STATS_DIR)/peak_counts.tsv

$(STATS_DIR)/peak_counts.tsv: $(PEAK_FILES)
> mkdir -p $(STATS_DIR)
> printf "sample\tpeaks\n" > $@
> @for s in $(CHIP_SAMPLES); do \
        printf "%s\t" "$$s" >> $@; \
        wc -l < $(PEAK_DIR)/$${s}_peaks.broadPeak >> $@; \
    done

# --------------------------------------------------
# Replicate comparison
# --------------------------------------------------

compare: $(STAMP_DIR)/compare.done

$(STAMP_DIR)/compare.done: $(PEAK_FILES)
> mkdir -p $(COMPARE_DIR) $(STATS_DIR) $(STAMP_DIR)
> bedtools intersect \
    -a $(PEAK_DIR)/ChIP_BCMminus_R1_peaks.broadPeak \
    -b $(PEAK_DIR)/ChIP_BCMminus_R2_peaks.broadPeak \
    -u \
    > $(COMPARE_DIR)/BCM_minus_shared.bed
> bedtools intersect \
    -a $(PEAK_DIR)/ChIP_BCMminus_R1_peaks.broadPeak \
    -b $(PEAK_DIR)/ChIP_BCMminus_R2_peaks.broadPeak \
    -v \
    > $(COMPARE_DIR)/BCM_minus_R1_unique.bed
> bedtools intersect \
    -a $(PEAK_DIR)/ChIP_BCMminus_R2_peaks.broadPeak \
    -b $(PEAK_DIR)/ChIP_BCMminus_R1_peaks.broadPeak \
    -v \
    > $(COMPARE_DIR)/BCM_minus_R2_unique.bed
> bedtools jaccard \
    -a $(PEAK_DIR)/ChIP_BCMminus_R1_peaks.broadPeak \
    -b $(PEAK_DIR)/ChIP_BCMminus_R2_peaks.broadPeak \
    > $(STATS_DIR)/BCM_minus_jaccard.txt
> bedtools intersect \
    -a $(PEAK_DIR)/ChIP_BCMplus_R1_peaks.broadPeak \
    -b $(PEAK_DIR)/ChIP_BCMplus_R2_peaks.broadPeak \
    -u \
    > $(COMPARE_DIR)/BCM_plus_shared.bed
> bedtools intersect \
    -a $(PEAK_DIR)/ChIP_BCMplus_R1_peaks.broadPeak \
    -b $(PEAK_DIR)/ChIP_BCMplus_R2_peaks.broadPeak \
    -v \
    > $(COMPARE_DIR)/BCM_plus_R1_unique.bed
> bedtools intersect \
    -a $(PEAK_DIR)/ChIP_BCMplus_R2_peaks.broadPeak \
    -b $(PEAK_DIR)/ChIP_BCMplus_R1_peaks.broadPeak \
    -v \
    > $(COMPARE_DIR)/BCM_plus_R2_unique.bed
> bedtools jaccard \
    -a $(PEAK_DIR)/ChIP_BCMplus_R1_peaks.broadPeak \
    -b $(PEAK_DIR)/ChIP_BCMplus_R2_peaks.broadPeak \
    > $(STATS_DIR)/BCM_plus_jaccard.txt
> touch $@

# --------------------------------------------------
# Clean generated output
# --------------------------------------------------

clean:
> rm -rf \
    $(REF_DIR) \
    $(RAW_DIR) \
    $(TRIM_DIR) \
    $(ALIGN_DIR) \
    $(COV_DIR) \
    $(PEAK_DIR) \
    $(COMPARE_DIR) \
    $(STATS_DIR) \
    $(STAMP_DIR)
