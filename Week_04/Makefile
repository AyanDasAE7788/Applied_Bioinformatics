SHELL := /bin/bash
.DELETE_ON_ERROR:

# --------------------------------------------------
# User settings
# --------------------------------------------------

SRR ?= SRR001666
N ?= 10000

# --------------------------------------------------
# Directories
# --------------------------------------------------

RAW_DIR := raw_data
TRIM_DIR := trimmed_data

QC_RAW_DIR := qc/raw
QC_TRIM_DIR := qc/trimmed
QC_FASTP_DIR := qc/fastp

STAMP_DIR := .stamps

# Stamp names include SRR and N.
# Changing either automatically causes the workflow
# to run again for the new dataset/subset.
DOWNLOAD_STAMP := $(STAMP_DIR)/download_$(SRR)_$(N).done
RAW_QC_STAMP := $(STAMP_DIR)/qc_raw_$(SRR)_$(N).done
TRIM_STAMP := $(STAMP_DIR)/trim_$(SRR)_$(N).done
TRIM_QC_STAMP := $(STAMP_DIR)/qc_trim_$(SRR)_$(N).done

.PHONY: all download qc_raw trim qc_trim clean

all: qc_trim


# --------------------------------------------------
# Create directories
# --------------------------------------------------

$(RAW_DIR) $(TRIM_DIR) $(QC_RAW_DIR) $(QC_TRIM_DIR) $(QC_FASTP_DIR) $(STAMP_DIR):
	mkdir -p $@


# --------------------------------------------------
# Download first N SRA spots
# --------------------------------------------------

download: $(DOWNLOAD_STAMP)

$(DOWNLOAD_STAMP): | $(RAW_DIR) $(STAMP_DIR)
	@command -v fastq-dump >/dev/null 2>&1 || { echo "ERROR: fastq-dump is not installed."; exit 1; }

	@rm -f \
		$(RAW_DIR)/$(SRR).fastq.gz \
		$(RAW_DIR)/$(SRR)_1.fastq.gz \
		$(RAW_DIR)/$(SRR)_2.fastq.gz \
		$(RAW_DIR)/raw_$(SRR).fastq.gz \
		$(RAW_DIR)/raw_$(SRR)_R1.fastq.gz \
		$(RAW_DIR)/raw_$(SRR)_R2.fastq.gz

	fastq-dump \
		--split-files \
		--gzip \
		-X $(N) \
		-O $(RAW_DIR) \
		$(SRR)

	@if [ -f "$(RAW_DIR)/$(SRR)_2.fastq.gz" ]; then \
		mv "$(RAW_DIR)/$(SRR)_1.fastq.gz" "$(RAW_DIR)/raw_$(SRR)_R1.fastq.gz"; \
		mv "$(RAW_DIR)/$(SRR)_2.fastq.gz" "$(RAW_DIR)/raw_$(SRR)_R2.fastq.gz"; \
	elif [ -f "$(RAW_DIR)/$(SRR)_1.fastq.gz" ]; then \
		mv "$(RAW_DIR)/$(SRR)_1.fastq.gz" "$(RAW_DIR)/raw_$(SRR).fastq.gz"; \
	elif [ -f "$(RAW_DIR)/$(SRR).fastq.gz" ]; then \
		mv "$(RAW_DIR)/$(SRR).fastq.gz" "$(RAW_DIR)/raw_$(SRR).fastq.gz"; \
	else \
		echo "ERROR: FASTQ output was not found."; \
		exit 1; \
	fi

	touch $(DOWNLOAD_STAMP)


# --------------------------------------------------
# FastQC before quality filtering
# --------------------------------------------------

qc_raw: $(RAW_QC_STAMP)

$(RAW_QC_STAMP): $(DOWNLOAD_STAMP) | $(QC_RAW_DIR) $(STAMP_DIR)
	@command -v fastqc >/dev/null 2>&1 || { echo "ERROR: FastQC is not installed."; exit 1; }

	@rm -f $(QC_RAW_DIR)/*$(SRR)*

	@if [ -f "$(RAW_DIR)/raw_$(SRR)_R2.fastq.gz" ]; then \
		fastqc \
			-o $(QC_RAW_DIR) \
			$(RAW_DIR)/raw_$(SRR)_R1.fastq.gz \
			$(RAW_DIR)/raw_$(SRR)_R2.fastq.gz; \
	else \
		fastqc \
			-o $(QC_RAW_DIR) \
			$(RAW_DIR)/raw_$(SRR).fastq.gz; \
	fi

	touch $(RAW_QC_STAMP)


# --------------------------------------------------
# Quality filtering with fastp
# --------------------------------------------------

trim: $(TRIM_STAMP)

$(TRIM_STAMP): $(DOWNLOAD_STAMP) | $(TRIM_DIR) $(QC_FASTP_DIR) $(STAMP_DIR)
	@command -v fastp >/dev/null 2>&1 || { echo "ERROR: fastp is not installed."; exit 1; }

	@rm -f \
		$(TRIM_DIR)/trimmed_$(SRR)* \
		$(QC_FASTP_DIR)/$(SRR)_fastp.*

	@if [ -f "$(RAW_DIR)/raw_$(SRR)_R2.fastq.gz" ]; then \
		fastp \
			-i $(RAW_DIR)/raw_$(SRR)_R1.fastq.gz \
			-I $(RAW_DIR)/raw_$(SRR)_R2.fastq.gz \
			-o $(TRIM_DIR)/trimmed_$(SRR)_R1.fastq.gz \
			-O $(TRIM_DIR)/trimmed_$(SRR)_R2.fastq.gz \
			--detect_adapter_for_pe \
			--html $(QC_FASTP_DIR)/$(SRR)_fastp.html \
			--json $(QC_FASTP_DIR)/$(SRR)_fastp.json; \
	else \
		fastp \
			-i $(RAW_DIR)/raw_$(SRR).fastq.gz \
			-o $(TRIM_DIR)/trimmed_$(SRR).fastq.gz \
			--html $(QC_FASTP_DIR)/$(SRR)_fastp.html \
			--json $(QC_FASTP_DIR)/$(SRR)_fastp.json; \
	fi

	touch $(TRIM_STAMP)


# --------------------------------------------------
# FastQC after quality filtering
# --------------------------------------------------

qc_trim: $(TRIM_QC_STAMP)

$(TRIM_QC_STAMP): $(TRIM_STAMP) | $(QC_TRIM_DIR) $(STAMP_DIR)
	@command -v fastqc >/dev/null 2>&1 || { echo "ERROR: FastQC is not installed."; exit 1; }

	@rm -f $(QC_TRIM_DIR)/*$(SRR)*

	@if [ -f "$(TRIM_DIR)/trimmed_$(SRR)_R2.fastq.gz" ]; then \
		fastqc \
			-o $(QC_TRIM_DIR) \
			$(TRIM_DIR)/trimmed_$(SRR)_R1.fastq.gz \
			$(TRIM_DIR)/trimmed_$(SRR)_R2.fastq.gz; \
	else \
		fastqc \
			-o $(QC_TRIM_DIR) \
			$(TRIM_DIR)/trimmed_$(SRR).fastq.gz; \
	fi

	touch $(TRIM_QC_STAMP)


# --------------------------------------------------
# Remove generated files
# --------------------------------------------------

clean:
	rm -rf $(RAW_DIR) $(TRIM_DIR) qc $(STAMP_DIR)