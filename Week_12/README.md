# Week 12: Generate RNA-Seq Count Matrices

## Overview

In this assignment, I performed transcript-level RNA-seq quantification and generated two count matrices:

1. **Transcript-level count matrix** — counts reported for individual transcripts.
2. **Gene-level count matrix** — transcript counts summed for all transcripts belonging to the same gene.

I used the same chromosome 22 RNA-seq dataset from Week 11, consisting of three Human Brain Reference (HBR) replicates and three Universal Human Reference (UHR) replicates.

The six samples were:

- HBR_Rep1
- HBR_Rep2
- HBR_Rep3
- UHR_Rep1
- UHR_Rep2
- UHR_Rep3

---

## Workflow

The workflow uses the chromosome 22 reference genome, GTF annotation, and paired-end RNA-seq reads from Week 11.

The main steps are:

1. Extract transcript sequences from the reference genome and GTF using `gffread`.
2. Build a transcriptome index with Salmon.
3. Quantify transcript abundance independently for all six RNA-seq samples using Salmon.
4. Read the `NumReads` values from each Salmon `quant.sf` file.
5. Combine the individual transcript counts into a single transcript-level count matrix.
6. Associate each transcript with its gene ID and gene name using the GTF annotation.
7. Sum transcript counts belonging to the same gene to create a gene-level count matrix.

Salmon produces estimated transcript counts, so some count values are fractional rather than integers. This is expected because ambiguously mapped reads can be probabilistically distributed between transcripts.

---

## Required Tools

The following programs must already be available in the `bioinfo` environment:

```text
salmon
gffread
R / Rscript
```

The Makefile does not install software automatically.

---

## Running the Workflow

From the `Week_12` directory, first check that the required programs are available:

```bash
make check-tools
```

Run the complete workflow with:

```bash
make
```

The Makefile will:

- generate the chromosome 22 transcriptome FASTA,
- build the Salmon index,
- quantify all six samples,
- and run the R script that generates both count matrices.

The R script can also be run separately after Salmon quantification:

```bash
Rscript src/make_count_matrices.R \
    quant \
    ../Week_11/gtf/chr22.gtf \
    results
```

---

## Count Matrix Results

Two matrices were successfully generated.

### Transcript-level matrix

File:

```text
results/transcript_count_matrix.csv
```

The transcript-level matrix contains:

- **4,559 transcript rows**
- **9 columns**

The columns are:

```text
transcript_id
gene_id
gene_name
HBR_Rep1
HBR_Rep2
HBR_Rep3
UHR_Rep1
UHR_Rep2
UHR_Rep3
```

Each row therefore represents an individual transcript and its estimated Salmon counts in the six samples.

### Gene-level matrix

File:

```text
results/gene_count_matrix.csv
```

The gene-level matrix contains:

- **1,408 gene rows**
- **8 columns**

The columns are:

```text
gene_id
gene_name
HBR_Rep1
HBR_Rep2
HBR_Rep3
UHR_Rep1
UHR_Rep2
UHR_Rep3
```

Gene-level counts were calculated by summing the transcript-level counts of all transcripts belonging to each gene.

---

## Comparison With Week 11 Visual Inspection

In Week 11, I visually examined RNA-seq coverage in IGV. Two genes that were particularly useful were `GRK3` and `SGSM1`.

### GRK3

The gene-level Salmon counts were:

| Sample | Count |
|---|---:|
| HBR_Rep1 | 201.069 |
| HBR_Rep2 | 284.053 |
| HBR_Rep3 | 260.857 |
| UHR_Rep1 | 170.729 |
| UHR_Rep2 | 122.045 |
| UHR_Rep3 | 125.016 |

The mean counts were approximately:

```text
HBR mean = 248.66
UHR mean = 139.26
```

This corresponds to approximately:

```text
HBR/UHR = 1.79-fold
```

This supports the Week 11 IGV observation that `GRK3` was expressed in all six samples, with generally stronger expression in HBR.

### SGSM1

The gene-level Salmon counts were:

| Sample | Count |
|---|---:|
| HBR_Rep1 | 144.041 |
| HBR_Rep2 | 178.968 |
| HBR_Rep3 | 149.656 |
| UHR_Rep1 | 10.071 |
| UHR_Rep2 | 15.615 |
| UHR_Rep3 | 17.341 |

The mean counts were approximately:

```text
HBR mean = 157.56
UHR mean = 14.34
```

This corresponds to approximately:

```text
HBR/UHR = 10.99-fold
```

This strongly supports the Week 11 visual observation that `SGSM1` is substantially more highly expressed in HBR than in UHR.

The exact fold change differs from the coverage-based estimate obtained in Week 11 because the two approaches measure expression differently. Week 11 used normalized genome coverage across exons, whereas Week 12 uses Salmon transcript-level estimated counts summarized to the gene level. Despite the different numerical estimates, both approaches show the same strong direction of expression difference.

---

## R Script

The script used to generate both matrices is:

```text
src/make_count_matrices.R
```

The script:

- reads Salmon `quant.sf` files,
- extracts transcript-to-gene information from the GTF,
- combines counts from all six samples,
- adds gene IDs and gene names,
- writes the transcript-level matrix,
- and sums transcript counts to generate the gene-level matrix.

---

## Experience With AI Prompting and Programming

I used AI assistance while developing and troubleshooting the workflow. AI was helpful for breaking the assignment into smaller computational steps, drafting the R code for combining Salmon outputs, interpreting command-line errors, and improving the reproducibility of the Makefile.

Rather than using the generated code without checking it, I ran each part of the workflow and verified the outputs. For example, I checked that all six Salmon `quant.sf` files were generated, confirmed the dimensions of both count matrices, inspected the matrix headers and several rows, and compared selected gene counts with the RNA-seq patterns observed visually in IGV during Week 11.

An important part of working with AI was providing specific information about file names, directory structure, expected outputs, and error messages. More detailed prompts generally produced more useful code and made troubleshooting easier.

---

## Challenges

One challenge was setting up the required software environment. Salmon, `gffread`, and R were not initially available in the active environment, so they had to be added to the existing Pixi `bioinfo` environment.

Another challenge was connecting transcript-level Salmon results to gene-level information. Salmon reports transcript identifiers and estimated counts, whereas the assignment required both gene names and gene-level counts. This required extracting transcript-to-gene relationships from the GTF annotation and then summing counts for transcripts belonging to the same gene.

I also had to understand why some Salmon counts were fractional. These values are expected because Salmon estimates the allocation of ambiguously mapped reads among transcripts.

Finally, the fold changes obtained from Salmon counts were not identical to the normalized coverage estimates from Week 11. This demonstrated that genome coverage and transcript-level quantification are related but different ways of measuring RNA-seq expression.

---

## Summary

The workflow successfully quantified six RNA-seq samples and generated both required count matrices.

The final transcript-level matrix contains **4,559 transcripts**, while the gene-level matrix contains **1,408 genes**. Both matrices include gene names and counts for all three HBR and three UHR replicates.

The quantitative results also supported the expression patterns observed visually in Week 11. `GRK3` was expressed in both sample types, while `SGSM1` showed a strong increase in HBR relative to UHR.