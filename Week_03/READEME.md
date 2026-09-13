# Week_03: Collaboration and Peer Review

## Repository Reviewed

For this assignment, I reviewed Bismark's Week 2 genomic data analysis repository.

The project analyzed the *Drosophila melanogaster* Lamin (`Lam`) gene using genomic FASTA, GFF3, and GTF files downloaded from NCBI.

---

## Safety Evaluation

Before executing the workflow, I inspected the `Makefile` using:

```bash
make -n
```

The Makefile downloads specific genomic files from NCBI using `curl`, processes the files locally using standard Unix tools such as `awk`, `grep`, and `zcat`, and optionally uses `samtools` to index the FASTA file.

I did not identify any commands that appeared malicious or that required elevated system privileges. The `clean` target uses:

```bash
rm -rf data
```

which removes the generated `data/` directory. This command is destructive to the generated files, but its scope is clearly limited to the assignment's data directory.

---

## README Evaluation

The README was detailed and provided information about the selected genome, data sources, commands, expected results, and IGV visualization.

The workflow was generally easy to understand. However, I identified several areas that could be improved for readability and reproducibility. In particular, the required software was not clearly summarized in one place, screenshots were stored directly in the main Week 2 directory, and the six-reading-frame section listed the six frame names rather than the six codons associated with a single nucleotide coordinate.

---

## Reproducibility

I tested the workflow by running:

```bash
make
```

The Makefile successfully downloaded and processed the genomic data.

The analysis reproduced the reported annotation results:

```text
TOTAL GFF3 records: 414876
Lamin-specific GFF3 records: 32
Lamin-specific GTF records: 40
```

The major feature counts also matched those reported in the README:

```text
exon 190710
CDS 163319
mRNA 30802
gene 17537
```

Therefore, the computational portion of the workflow was reproducible on my system.

---

## Comparison With My Week 2 Solution

The reviewed solution and my Week 2 solution used different approaches.

The reviewed solution contained a more extensive Makefile workflow. It downloaded FASTA, GFF3, and GTF files, extracted Lamin-specific annotations, counted annotation features, and provided a `clean` target. This provided stronger automation for several parts of the analysis.

My solution was simpler and more directly focused on the required FASTA/GFF download and IGV visualization tasks. My reading-frame analysis also reported the possible codons at a selected nucleotide coordinate, while the reviewed solution listed only the six reading-frame names.

Overall, the reviewed solution had stronger automation, while my solution was simpler and more directly aligned with some of the assignment questions. Combining the automation of the reviewed solution with clearer organization and documentation would improve the workflow.

---

## Changes Made

I made several changes to improve the structure and readability of the Week 2 assignment.

The IGV screenshots were moved into a dedicated:

```text
images/
```

directory instead of being stored directly in the Week 2 directory.

The separate `screenshots.md` file was removed, and the image paths in the main `README.md` were updated so that all figures are displayed directly from the `images/` directory.

I also improved the README by:

- adding clearer software requirements,
- clarifying the distinction between biological chromosomes and FASTA sequence records,
- improving the explanation of genome completeness,
- clarifying the six-reading-frame question.

---

## Pull Request

I contributed these changes back to the original repository through a pull request.

**Pull request:** https://github.com/Bismarkacquah/BMB852/pull/1

Thank you.