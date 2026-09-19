# Week_04: Obtain FASTQ Data from SRA

## Genome of Interest

For this assignment, I continued working with the genome selected in Week 02:

- **Organism:** *Escherichia coli* str. K-12 substr. MG1655
- **RefSeq assembly:** `GCF_000005845.2`
- **Assembly name:** `ASM584v2`
- **Reference chromosome:** `NC_000913.3`

The goal of this assignment was to investigate how much sequencing data are publicly available for MG1655 and to develop a reproducible Makefile workflow that downloads a subset of FASTQ reads from SRA, evaluates their quality, applies quality filtering, and performs QC again.

---

# Required Software

The workflow was run in the `bioinfo` environment.

```bash
conda activate bioinfo
```

The main tools used were:

```bash
fastq-dump --version
fastqc --version
fastp --version
```

Versions used:

```text
fastq-dump 3.0.0
FastQC 0.12.1
fastp 1.3.6
```

---

# Availability of MG1655 Sequencing Data

I searched NCBI SRA using:

```text
"Escherichia coli str. K-12 substr. MG1655"[Organism]
```

The search was performed on **September 19, 2026**.

The main SRA search returned:

```text
20,542 experiment records
```

When the search results were transferred to the SRA Run Selector, they corresponded to:

```text
21,869 sequencing runs
12.16 TB of data
30.79 trillion bases
```

The difference between the number of experiments and runs occurs because an SRA experiment can contain more than one sequencing run.

These results show that MG1655 is extremely well represented in public sequencing databases.

---

# Sequencing Strategy

Metadata for the 21,869 runs were downloaded from the SRA Run Selector as:

```text
metadata/SraRunTable.csv
```

The sequencing strategy was summarized using the `Assay Type` field.

| Assay type | Number of runs |
| --- | ---: |
| WGS | 6,916 |
| RNA-Seq | 5,839 |
| AMPLICON | 4,281 |
| OTHER | 2,125 |
| ChIP-Seq | 1,429 |
| CLONE | 405 |
| RIP-Seq | 223 |
| Tn-Seq | 216 |
| ncRNA-Seq | 146 |
| Bisulfite-Seq | 70 |
| WGA | 51 |
| ATAC-seq | 40 |
| MNase-Seq | 36 |
| Hi-C | 23 |
| EST | 22 |
| ssRNA-Seq | 16 |
| POOLCLONE | 9 |
| MeDIP-Seq | 9 |
| VALIDATION | 6 |
| Ribo-seq | 6 |
| Targeted-Capture | 1 |

The most common sequencing strategy was **whole-genome sequencing (WGS)**, followed by **RNA-Seq** and **amplicon sequencing**.

The large number of RNA-Seq runs also shows that MG1655 has been extensively studied at the transcriptomic level in addition to genome sequencing.

---

# Sequencing Platforms

The platform distribution was:

| Platform | Number of runs |
| --- | ---: |
| ILLUMINA | 19,998 |
| PACBIO_SMRT | 657 |
| OXFORD_NANOPORE | 524 |
| ELEMENT | 435 |
| ION_TORRENT | 132 |
| ABI_SOLID | 82 |
| LS454 | 31 |
| DNBSEQ | 8 |
| HELICOS | 2 |

Illumina dominates the available sequencing data.

However, MG1655 has also been sequenced using several long-read and older sequencing technologies, including PacBio SMRT, Oxford Nanopore, Ion Torrent, ABI SOLiD, and 454 sequencing.

Some of the most frequently represented sequencing instruments were:

```text
Illumina NovaSeq 6000    5,593
Illumina MiSeq           3,050
NextSeq 500              2,704
Illumina HiSeq 2500      2,642
Illumina HiSeq 2000      1,472
NextSeq 2000               936
Illumina HiSeq 4000        848
NextSeq 550                784
Illumina HiSeq X            519
PacBio RS                   493
Element AVITI               435
MinION                       372
```

---

# Library Layout

The SRA metadata showed:

| Library layout | Number of runs |
| --- | ---: |
| PAIRED | 14,843 |
| SINGLE | 7,026 |

Paired-end sequencing therefore represents the majority of the available MG1655 runs.

---

# What I Found Interesting

I was surprised by both the amount and diversity of sequencing data available for MG1655.

More than **21,000 sequencing runs** are publicly available for this single bacterial strain. These data represent many different types of experiments, including WGS, RNA-Seq, ChIP-Seq, Tn-Seq, ATAC-seq, Hi-C, ribosome profiling, and several other approaches.

The sequencing technologies also span several generations. The database contains older technologies such as 454 and ABI SOLiD, many generations of Illumina instruments, and newer long-read technologies such as PacBio and Oxford Nanopore.

This reflects how extensively *E. coli* K-12 MG1655 has been used as a model organism and how sequencing technologies used to study it have changed over time.

---

# FASTQ Dataset Selected

For the FASTQ analysis, I used:

```text
SRR001666
```

This is a paired-end Illumina whole-genome sequencing run from *E. coli* K-12 MG1655.

Rather than downloading the complete run, I downloaded only the first:

```text
N = 10,000 SRA spots
```

Because this experiment is paired-end, the 10,000 spots produced:

```text
10,000 R1 reads
10,000 R2 reads
```

The number of reads was verified using:

```bash
zcat raw_data/raw_SRR001666_R1.fastq.gz | wc -l
zcat raw_data/raw_SRR001666_R2.fastq.gz | wc -l
```

Both commands returned:

```text
40000
```

Each FASTQ record contains four lines, therefore:

```text
40,000 lines = 10,000 reads
```

---

# Running the Workflow

The default settings in the Makefile are:

```text
SRR = SRR001666
N = 10000
```

The complete workflow can be reproduced using:

```bash
make
```

The workflow performs:

```text
SRA
 ↓
first N spots
 ↓
raw FASTQ
 ↓
FastQC
 ↓
fastp quality filtering
 ↓
filtered FASTQ
 ↓
FastQC
```

The generated files are organized into directories according to their data type:

```text
Week_04/
├── README.md
├── Makefile
├── metadata/
│   └── SraRunTable.csv
├── raw_data/
├── trimmed_data/
└── qc/
    ├── raw/
    ├── fastp/
    └── trimmed/
```

Individual steps can also be run separately.

### Download reads

```bash
make download
```

### Raw-read QC

```bash
make qc_raw
```

### Quality filtering

```bash
make trim
```

### QC after filtering

```bash
make qc_trim
```

The accession and number of spots can be changed without editing the Makefile:

```bash
make SRR=SRR001666 N=5000
```

The download step automatically recognizes whether the SRA accession produces single-end or paired-end FASTQ files.

---

# Raw Read Quality

FastQC was first run on the original 10,000 paired-end reads.

## R1

The R1 reads passed all FastQC modules.

Important observations included:

- 10,000 reads
- 36 bp read length
- approximately 50% GC
- no substantial adapter contamination
- no overrepresented sequence problem
- very low duplication
- essentially no ambiguous N bases

The per-base sequence quality decreased slightly toward the 3' end but remained within the FastQC passing criteria.

## R2

R2 passed most FastQC modules, but:

```text
FAIL: Per base sequence quality
```

The quality was high at the beginning of the reads but progressively decreased toward the 3' end.

The final portion of the 36 bp reads contained a much broader distribution of Phred quality scores, including many low-quality bases.

Other metrics, including adapter content, sequence duplication, GC content, N content, and overrepresented sequences, passed.

---

# Quality Filtering

Quality filtering was performed using `fastp`.

For paired-end reads, the Makefile uses:

```bash
fastp \
    -i raw_data/raw_SRR001666_R1.fastq.gz \
    -I raw_data/raw_SRR001666_R2.fastq.gz \
    -o trimmed_data/trimmed_SRR001666_R1.fastq.gz \
    -O trimmed_data/trimmed_SRR001666_R2.fastq.gz \
    --detect_adapter_for_pe
```

`fastp` also generates HTML and JSON reports in:

```text
qc/fastp/
```

---

# QC After Filtering

After quality filtering, each FASTQ file contained:

```text
9,503 reads
```

Therefore, 497 of the original 10,000 paired read records were removed during filtering.

## R1 after filtering

R1 continued to pass the FastQC per-base sequence quality test and the other FastQC modules.

## R2 after filtering

R2 still showed:

```text
FAIL: Per base sequence quality
```

although the lower-quality read pairs had been filtered from the dataset.

The retained R2 reads were still 36 bp long, indicating that the main effect of this filtering step was removal of entire lower-quality read pairs rather than extensive shortening of the retained reads.

---

# Did Quality Filtering Make a Difference?

Yes, but the improvement was limited.

The original dataset contained 10,000 paired reads, while 9,503 pairs remained after `fastp` filtering. This shows that the filtering step removed a subset of poorer-quality reads.

R1 already had high sequence quality before filtering and remained high quality afterward.

R2 had a clear decline in sequence quality toward the 3' end before filtering. Although `fastp` removed lower-quality read pairs, the post-filter FastQC report still failed the Per Base Sequence Quality module for R2.

Therefore, the filtering step improved the dataset by removing poorer-quality read pairs, but it did not completely eliminate the positional quality decline observed toward the end of R2.

---

# Summary

*E. coli* K-12 MG1655 has an exceptionally large amount of publicly available sequencing evidence. The SRA Run Selector contained **21,869 runs**, representing approximately **30.79 trillion bases** and **12.16 TB of sequencing data**.

Most runs were generated using Illumina sequencing, although PacBio, Oxford Nanopore, and several other technologies were also represented. WGS, RNA-Seq, and amplicon sequencing were the three most common experimental strategies.

For the FASTQ workflow, the first 10,000 spots from `SRR001666` were downloaded and analyzed. Raw FastQC showed excellent R1 quality but declining 3' quality in R2. `fastp` quality filtering retained 9,503 read pairs. The filtering removed some lower-quality reads, although R2 continued to fail FastQC's Per Base Sequence Quality module afterward.

The Makefile automates the complete process and allows a different SRA accession or read subset size to be specified without changing the workflow itself.