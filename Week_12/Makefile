SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c
.DELETE_ON_ERROR:
.RECIPEPREFIX := >

SAMPLES := HBR_Rep1 HBR_Rep2 HBR_Rep3 UHR_Rep1 UHR_Rep2 UHR_Rep3

DATA := ../Week_11/data
GENOME := ../Week_11/reference/chr22.genome.fa
GTF := ../Week_11/gtf/chr22.gtf

REF_DIR := reference
QUANT_DIR := quant
RESULTS_DIR := results
LOG_DIR := logs

TRANSCRIPTOME := $(REF_DIR)/chr22_transcripts.fa
SALMON_INDEX := $(REF_DIR)/salmon_index

R_SCRIPT := src/make_count_matrices.R

QUANT_FILES := $(SAMPLES:%=$(QUANT_DIR)/%/quant.sf)

.PHONY: all check-tools transcriptome index quant matrices clean

all: matrices

# ------------------------------------------------------------
# Check required software
# ------------------------------------------------------------

check-tools:
> @for tool in salmon gffread Rscript; do \
      command -v $$tool >/dev/null 2>&1 || { \
          echo "ERROR: $$tool not found."; \
          exit 1; \
      }; \
  done
> @echo "Required tools found."

# ------------------------------------------------------------
# Build transcriptome FASTA
# ------------------------------------------------------------

transcriptome: $(TRANSCRIPTOME)

$(TRANSCRIPTOME): $(GENOME) $(GTF)
> mkdir -p $(REF_DIR)
> gffread $(GTF) \
      -g $(GENOME) \
      -w $(TRANSCRIPTOME)

# ------------------------------------------------------------
# Build Salmon index
# ------------------------------------------------------------

index: $(SALMON_INDEX)/versionInfo.json

$(SALMON_INDEX)/versionInfo.json: $(TRANSCRIPTOME)
> rm -rf $(SALMON_INDEX)
> salmon index \
      -t $(TRANSCRIPTOME) \
      -i $(SALMON_INDEX) \
      -p 4

# ------------------------------------------------------------
# Quantify each sample
# ------------------------------------------------------------

$(QUANT_DIR)/%/quant.sf: $(SALMON_INDEX)/versionInfo.json
> mkdir -p $(QUANT_DIR)/$* $(LOG_DIR)
> R1=$$(ls $(DATA)/$*_*.read1.fastq.gz); \
  R2=$$(ls $(DATA)/$*_*.read2.fastq.gz); \
  salmon quant \
      -i $(SALMON_INDEX) \
      -l A \
      -1 "$$R1" \
      -2 "$$R2" \
      --validateMappings \
      -p 4 \
      -o $(QUANT_DIR)/$* \
      2> $(LOG_DIR)/$*_salmon.log

quant: $(QUANT_FILES)

# ------------------------------------------------------------
# Generate count matrices
# ------------------------------------------------------------

matrices: quant
> mkdir -p $(RESULTS_DIR)
> Rscript $(R_SCRIPT) \
      $(QUANT_DIR) \
      $(GTF) \
      $(RESULTS_DIR)

# ------------------------------------------------------------
# Remove generated outputs
# ------------------------------------------------------------

clean:
> rm -rf \
      $(REF_DIR) \
      $(QUANT_DIR) \
      $(RESULTS_DIR) \
      $(LOG_DIR)
