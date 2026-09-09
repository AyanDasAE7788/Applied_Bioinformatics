# Week 02: Visualize Genomic Data

## Genome Selected

For this assignment, I selected *Escherichia coli* K-12 MG1655 bacteria genome.

- **RefSeq Assembly Accession:** `GCF_000005845.2`
- **Assembly Name:** `ASM584v2`
- **Reference Chromosome:** `NC_000913.3`
- **Data Source:** NCBI RefSeq

---

# Reproducing the Analysis

To download the genomic data used in this assignment, a reviewer can create a new working directory, create a `Makefile` using the code provided below, and run it to download the same FASTA and GFF files from NCBI RefSeq.

## Required Command-Line Tools

The following command-line tools are needed to reproduce this analysis:

```bash
make --version
curl --version
samtools --version | head -n 1
```

I performed the analysis inside the `bioinfo` environment used for this course. If the same environment is available, activate it using:

```bash
micromamba activate bioinfo
```

or:

```bash
conda activate bioinfo
```

---

## What Does the Makefile Do?

The `Makefile` used in this assignment automatically downloads two files for the *Escherichia coli* K-12 MG1655 reference genome:

1. The genomic FASTA sequence:

```text
GCF_000005845.2_ASM584v2_genomic.fna.gz
```

2. The corresponding GFF annotation file:

```text
GCF_000005845.2_ASM584v2_genomic.gff.gz
```

Both files are downloaded from the same NCBI RefSeq assembly:

```text
GCF_000005845.2_ASM584v2
```

The Makefile also automatically creates a `data/` directory and places the downloaded files inside it.

---

## Reproducing the Download

First, create a new directory for the analysis:

```bash
mkdir Ecoli_MG1655
```

Enter the directory:

```bash
cd Ecoli_MG1655
```

Create a file named exactly:

```text
Makefile
```

For example:

```bash
touch Makefile
```

Open the file using a text editor such as VS Code:

```bash
code Makefile
```

Paste the following code into the `Makefile`:

```makefile
ACCESSION = GCF_000005845.2_ASM584v2
BASE_URL = https://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/000/005/845/$(ACCESSION)

FASTA = data/$(ACCESSION)_genomic.fna.gz
GFF = data/$(ACCESSION)_genomic.gff.gz

all: $(FASTA) $(GFF)

$(FASTA):
	mkdir -p data
	curl -L $(BASE_URL)/$(ACCESSION)_genomic.fna.gz -o $(FASTA)

$(GFF):
	mkdir -p data
	curl -L $(BASE_URL)/$(ACCESSION)_genomic.gff.gz -o $(GFF)

clean:
	rm -f $(FASTA) $(GFF)
```

> **Note:** The command lines under `$(FASTA):`, `$(GFF):`, and `clean:` must begin with a TAB character rather than spaces.

Save the `Makefile`.

---

## Running the Makefile

From the directory containing the `Makefile`, run:

```bash
make
```

The Makefile will automatically create:

```text
data/
```

and download the two genomic data files into it.

The resulting directory should look like:

```text
Ecoli_MG1655/
├── Makefile
└── data/
    ├── GCF_000005845.2_ASM584v2_genomic.fna.gz
    └── GCF_000005845.2_ASM584v2_genomic.gff.gz
```

---

## Genome Size

I calculated the genome size using (when in the folder containing the data folder):

```bash
zcat data/GCF_000005845.2_ASM584v2_genomic.fna.gz | grep -v "^>" | tr -d '\n' | wc -c
```

Output:

```text
4641652
```

Therefore, the genome size of *E. coli* K-12 MG1655 is **4,641,652 bp**, or approximately **4.64 Mb**.

---

## Number of Chromosomes

I counted the number of FASTA sequence headers using:

```bash
zgrep -c "^>" data/GCF_000005845.2_ASM584v2_genomic.fna.gz
```

Output:

```text
1
```

Therefore, this genome assembly contains **one chromosome**.

---

## Number of Annotations

I counted all non-comment feature records in the GFF annotation file using:

```bash
zgrep -v "^#" data/GCF_000005845.2_ASM584v2_genomic.gff.gz | wc -l
```

Output:

```text
9523
```

Therefore, the GFF file contains **9,523 annotation records**.

---

## Completeness of the Genome Build

I think this genome build is highly complete. The assembly has one signle chromosome rather than many fragmented contigs/scaffolds. *E. coli* K-12 MG1655 is also a well-established reference strain, making this assembly suitable for genome analysis and visualization.

---

# Genome Visualization in IGV

## Gene Density

The genes in the region I inspected (near the *rna* gene) appeared to be **very tightly packed**. Some genes **overlapped** with each other.

The approximate gene-to-gene distances from 5 intergenic regions (starting from *rnk* to *citF*) were: **232, 113, 50, 3 and 12 bp**.

![Gene density in IGV](images/gene_density.png)

---

## Chromosome Coordinate Inspected

I selected the following coordinate for closer inspection:

```text
NC_000913.3:644,595
```

At this position, I observed:

> The coordinate lies in the *rna* gene. There are five stop codons and two start codons (including both strands) near this coordinate. It is a C/G nucleotide.

---

## Six Possible Reading Frames

For the coordinate selected above, the possible codons are:

| Strand | Reading Frame | Codon |
|---|---|---|
| Forward (+) | +1 | `His` |
| Forward (+) | +2 | `Ser` |
| Forward (+) | +3 | `Phe` |
| Reverse (-) | -1 | `Val` |
| Reverse (-) | -2 | `STOP` |
| Reverse (-) | -3 | `Glu` |

### IGV View of the Sequence

![Visual inspection of sequence region near coordinate](images/nearby_sequence_1.png)
![Visual inspection of sequence region near coordinate](images/nearby_sequence_2.png)

---

## Feature Type Displayed in the Annotation Track

The GFF annotation file was displayed in IGV as a feature track. Shown features were: **gene / CDS / tRNA / rRNA / ncRNA / other**

The feature I inspected at the coordinate was a: **gene & CDS**

---

## Strand Orientation

The annotation features were colored according to their strand orientation.

- **Forward strand (+):** Dark teal color
- **Reverse strand (-):** Salmon color

![Features colored by strand orientation](images/strand_orientation.png)

---

## Summary

The *E. coli* K-12 MG1655 genome is approximately **4.64 Mb** in size and consists of **one chromosome**. The GFF annotation file contains **9,523 annotation records**. Visualization in IGV makes it possible to inspect genome organization, gene density, annotated features, nucleotide sequences, reading frames, and strand orientation.