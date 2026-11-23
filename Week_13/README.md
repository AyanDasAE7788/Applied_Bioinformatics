# Week 13: Evaluate RNA-seq Simulations

## Overview

The goal of this assignment was to evaluate the performance of differential expression methods using simulated RNA-seq data where the true state of each gene was already known.

I simulated RNA-seq count data for two experimental conditions and analyzed the data using both **edgeR** and **DESeq2**. Because the simulation records whether each gene was actually changed or unchanged, I could compare the known truth with the differential expression results.

Genes were classified as:

- **TP (True Positive):** changed gene with FDR < 0.05
- **FP (False Positive):** unchanged gene with FDR < 0.05
- **TN (True Negative):** unchanged gene with FDR >= 0.05
- **FN (False Negative):** changed gene with FDR >= 0.05

Genes that failed the coverage filter were treated as nonsignificant in this workflow.

---

## Simulation

The simulation contained:

```text
Total genes:       2000
Changed genes:      400
Unchanged genes:   1600
```

For the original simulation:

```text
Filter pass: 1967
Filter fail:   33
```

Three replicates were simulated for each of two conditions.

The same simulated count matrix was analyzed independently with edgeR and DESeq2.

---

## Original Simulation Results

The evaluation results were:

| Method | TP | FP | TN | FN |
|---|---:|---:|---:|---:|
| edgeR | 242 | 12 | 1588 | 158 |
| DESeq2 | 242 | 12 | 1588 | 158 |

Both methods therefore had the same overall confusion-matrix counts in the first simulation.

### Performance scores

| Metric | edgeR | DESeq2 |
|---|---:|---:|
| Accuracy | 0.915 | 0.915 |
| Precision | 0.953 | 0.953 |
| Recall | 0.605 | 0.605 |
| Specificity | 0.993 | 0.993 |
| F1 score | 0.740 | 0.740 |
| MCC | 0.718 | 0.718 |
| Observed FDR | 0.047 | 0.047 |

The observed false discovery rate was approximately 4.7%, which was close to the FDR threshold of 5%.

Although the summary counts were identical, edgeR and DESeq2 did not make exactly the same decision for every gene.

```text
Same decision:      1968
Different decision:   32
Agreement:           98.4%
```

This means that the two methods sometimes classified different individual genes as significant even though their final TP, FP, TN, and FN totals were the same.

---

## Detailed Inspection of False Positives and False Negatives

To understand why some genes were misclassified, I inspected the actual replicate counts rather than relying only on the group means. Three representative genes are shown below.

### gene_0360

- **Known simulation state:** unchanged
- **Coverage filter:** pass
- **edgeR:** FDR = 0.036817 (FP)
- **DESeq2:** FDR = 0.017915 (FP)

| A_Rep1 | A_Rep2 | A_Rep3 | B_Rep1 | B_Rep2 | B_Rep3 | Mean A | Mean B |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 683 | 633 | 426 | 371 | 222 | 205 | 580.67 | 266 |

`gene_0360` was simulated as unchanged, but the observed replicate data produced a large difference between the groups. The average count was about 580.7 in condition A and 266 in condition B. Because the random simulated counts made this unchanged gene appear strongly different between conditions, both methods assigned an FDR below 0.05 and classified it as significant. It is therefore a false positive.

### gene_0032

- **Known simulation state:** changed
- **Coverage filter:** pass
- **edgeR:** FDR = 0.971447 (FN)
- **DESeq2:** FDR = 0.970110 (FN)

| A_Rep1 | A_Rep2 | A_Rep3 | B_Rep1 | B_Rep2 | B_Rep3 | Mean A | Mean B |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 243 | 144 | 143 | 296 | 179 | 86 | 176.67 | 187 |

`gene_0032` was truly changed in the simulation, but the observed counts did not show a clear difference between conditions. The average counts were approximately 176.7 for A and 187 for B. Because the realized difference was small relative to the variability in the simulated samples, both methods produced a large FDR and failed to detect the true change. It is therefore a false negative.

### gene_0114

- **Known simulation state:** changed
- **Coverage filter:** fail
- **edgeR:** FDR = 1.000000 (FN)
- **DESeq2:** FDR = 1.000000 (FN)

| A_Rep1 | A_Rep2 | A_Rep3 | B_Rep1 | B_Rep2 | B_Rep3 | Mean A | Mean B |
|---:|---:|---:|---:|---:|---:|---:|---:|
| 4 | 4 | 9 | 0 | 1 | 0 | 5.67 | 0.33 |

`gene_0114` was simulated as changed, but it had very little sequencing coverage. Across all six replicates there were only 18 total counts, and the gene failed the coverage filter. With so little information, neither method had enough evidence to call the gene significantly differentially expressed, so it was classified as a false negative.

These examples show two different reasons for errors. A false positive can occur when random sampling makes an unchanged gene appear different between groups. False negatives can occur when a true expression change is obscured by biological/sampling variability or when read coverage is too low to provide sufficient statistical evidence.

## Scoring the Methods

Several metrics were calculated from TP, FP, TN, and FN.

### Accuracy

Accuracy measures the proportion of all genes that were classified correctly.

```text
Accuracy = (TP + TN) / (TP + FP + TN + FN)
```

### Precision

Precision measures how often a gene called significant was truly changed.

```text
Precision = TP / (TP + FP)
```

### Recall

Recall, or sensitivity, measures the fraction of truly changed genes that were detected.

```text
Recall = TP / (TP + FN)
```

### F1 Score

The F1 score combines precision and recall into one number:

```text
F1 = 2 * TP / (2 * TP + FP + FN)
```

The F1 score was approximately **0.740** for both methods in the original simulation.

### Matthews Correlation Coefficient

I also calculated the Matthews Correlation Coefficient (MCC), which uses all four values in the confusion matrix. MCC is useful because it summarizes classification performance while considering both positive and negative classes.

The original MCC was approximately:

```text
edgeR  = 0.718
DESeq2 = 0.718
```

---

## Do edgeR and DESeq2 Produce the Same Results?

Not completely.

In the original simulation, both methods produced exactly the same total numbers of TP, FP, TN, and FN and therefore had identical overall performance scores.

However, they disagreed on **32 individual genes**.

Their gene-level agreement was:

```text
98.4%
```

Therefore, the methods were highly similar but did not make identical differential-expression calls.

---

## Which Method Was More Accurate?

For the original simulation, neither method was more accurate. Both had:

```text
Accuracy = 0.915
F1       = 0.740
MCC      = 0.718
```

However, the rerun showed that their relative performance can change depending on the simulated dataset.

In the rerun:

| Metric | edgeR | DESeq2 |
|---|---:|---:|
| TP | 213 | 228 |
| FP | 8 | 6 |
| TN | 1592 | 1594 |
| FN | 187 | 172 |
| Accuracy | 0.9025 | 0.9110 |
| Precision | 0.9638 | 0.9744 |
| Recall | 0.5325 | 0.5700 |
| Specificity | 0.9950 | 0.9963 |
| F1 | 0.6860 | 0.7192 |
| MCC | 0.6730 | 0.7047 |

In this particular rerun, **DESeq2 performed slightly better than edgeR**. It detected more true positives, produced fewer false positives and false negatives, and had higher accuracy, recall, F1, and MCC.

Therefore, based on these two simulations, I would not conclude that one method is always superior. Their performance depends partly on the particular RNA-seq dataset and random variation present in the simulation.

---

## Does Rerunning the Simulation Give the Same Results?

No.

The original simulation used one random seed, while the rerun used a different seed.

The original results were:

```text
edgeR:  TP = 242, FP = 12, TN = 1588, FN = 158
DESeq2: TP = 242, FP = 12, TN = 1588, FN = 158
```

The rerun produced:

```text
edgeR:  TP = 213, FP = 8, TN = 1592, FN = 187
DESeq2: TP = 228, FP = 6, TN = 1594, FN = 172
```

The number of genes passing the coverage filter also changed from 1967 to 1975.

The edgeR/DESeq2 agreement changed from:

```text
Original: 98.4%
Rerun:    97.95%
```

The results therefore depend on the random counts generated during the simulation. Using the same random seed reproduces the same simulation, while changing the seed creates a different simulated dataset and can change the differential-expression results.

---

## Scripts

The scripts used for the analysis are located in:

```text
src/simulate_and_de.R
src/evaluate_results.R
```

`simulate_and_de.R`:

- simulates RNA-seq counts,
- records the known changed/unchanged status,
- performs coverage filtering,
- runs edgeR,
- runs DESeq2,
- and saves the differential expression results.

`evaluate_results.R`:

- compares the known status with the FDR results,
- calculates TP, FP, TN, and FN,
- calculates performance metrics,
- identifies false positive and false negative genes,
- and compares edgeR with DESeq2.

---

## Running the Analysis

Check that edgeR and DESeq2 are available:

```bash
make check-tools
```

Run the main simulation and evaluation:

```bash
make
```

Run a second simulation with a different random seed:

```bash
make rerun
```

The main evaluation summary is saved as:

```text
results/evaluation_summary.csv
```

Misclassified genes are saved as:

```text
results/misclassified_genes.csv
```

The edgeR and DESeq2 gene-level comparison is saved as:

```text
results/method_comparison.csv
```

---

## Summary

Both edgeR and DESeq2 performed well on the simulated RNA-seq data.

In the original simulation, both methods achieved 91.5% accuracy and had identical overall TP, FP, TN, and FN counts. However, they still disagreed on 32 individual genes.

False positives occurred when random variation caused unchanged genes to appear different between the two groups. False negatives occurred when the observed effect was weak, noisy, close to the statistical threshold, or when coverage was too low.

When the simulation was repeated with a different random seed, the results changed. In the rerun, DESeq2 performed slightly better than edgeR. This demonstrates that the apparent performance of a differential-expression method can vary depending on the specific dataset and random variation in the simulated experiment.