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
