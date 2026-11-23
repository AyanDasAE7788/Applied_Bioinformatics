#!/usr/bin/env Rscript

# ------------------------------------------------------------
# Week 13
# Inspect raw replicate counts for representative
# false-positive and false-negative genes.
# ------------------------------------------------------------

sim <- read.csv(
    "results/simulation_counts.csv",
    stringsAsFactors = FALSE,
    check.names = FALSE
)

edge <- read.csv(
    "results/edgeR.csv",
    stringsAsFactors = FALSE
)

deseq <- read.csv(
    "results/deseq2.csv",
    stringsAsFactors = FALSE
)

genes <- c(
    "gene_0360",   # FP example
    "gene_0032",   # FN example
    "gene_0114"    # low-coverage/filter-fail FN
)

samples <- c(
    "A_Rep1", "A_Rep2", "A_Rep3",
    "B_Rep1", "B_Rep2", "B_Rep3"
)

classify_gene <- function(status, fdr) {

    if (is.na(fdr)) {
        fdr <- 1
    }

    if (status == "changed" && fdr < 0.05) {
        return("TP")
    }

    if (status == "unchanged" && fdr < 0.05) {
        return("FP")
    }

    if (status == "unchanged" && fdr >= 0.05) {
        return("TN")
    }

    return("FN")
}

out <- file(
    "results/fp_fn_examples.md",
    open = "w"
)

writeLines(
    "## Detailed Inspection of False Positives and False Negatives",
    out
)

writeLines(
    c(
        "",
        "To understand why some genes were misclassified, I inspected the actual replicate counts rather than relying only on the group means. Three representative genes are shown below."
    ),
    out
)

for (gene in genes) {

    s <- sim[sim$gene == gene, , drop = FALSE]
    e <- edge[edge$gene == gene, , drop = FALSE]
    d <- deseq[deseq$gene == gene, , drop = FALSE]

    if (nrow(s) == 0 || nrow(e) == 0 || nrow(d) == 0) {
        stop(paste("Could not find", gene))
    }

    edge_class <- classify_gene(
        s$status[1],
        e$FDR[1]
    )

    deseq_class <- classify_gene(
        s$status[1],
        d$FDR[1]
    )

    writeLines(
        c(
            "",
            paste0("### ", gene),
            "",
            paste0(
                "- **Known simulation state:** ",
                s$status[1]
            ),
            paste0(
                "- **Coverage filter:** ",
                s$filter[1]
            ),
            paste0(
                "- **edgeR:** FDR = ",
                format(round(e$FDR[1], 6), nsmall = 6),
                " (", edge_class, ")"
            ),
            paste0(
                "- **DESeq2:** FDR = ",
                format(round(d$FDR[1], 6), nsmall = 6),
                " (", deseq_class, ")"
            ),
            "",
            "| A_Rep1 | A_Rep2 | A_Rep3 | B_Rep1 | B_Rep2 | B_Rep3 | Mean A | Mean B |",
            "|---:|---:|---:|---:|---:|---:|---:|---:|",
            paste0(
                "| ",
                paste(
                    c(
                        s[1, samples],
                        round(s$mean_A[1], 2),
                        round(s$mean_B[1], 2)
                    ),
                    collapse = " | "
                ),
                " |"
            )
        ),
        out
    )

    if (gene == "gene_0360") {

        writeLines(
            c(
                "",
                paste0(
                    "`gene_0360` was simulated as unchanged, but the observed replicate data produced a large difference between the groups. The average count was about ",
                    round(s$mean_A[1], 1),
                    " in condition A and ",
                    round(s$mean_B[1], 1),
                    " in condition B. Because the random simulated counts made this unchanged gene appear strongly different between conditions, both methods assigned an FDR below 0.05 and classified it as significant. It is therefore a false positive."
                )
            ),
            out
        )
    }

    if (gene == "gene_0032") {

        writeLines(
            c(
                "",
                paste0(
                    "`gene_0032` was truly changed in the simulation, but the observed counts did not show a clear difference between conditions. The average counts were approximately ",
                    round(s$mean_A[1], 1),
                    " for A and ",
                    round(s$mean_B[1], 1),
                    " for B. Because the realized difference was small relative to the variability in the simulated samples, both methods produced a large FDR and failed to detect the true change. It is therefore a false negative."
                )
            ),
            out
        )
    }

    if (gene == "gene_0114") {

        total_count <- sum(
            as.numeric(
                s[1, samples]
            )
        )

        writeLines(
            c(
                "",
                paste0(
                    "`gene_0114` was simulated as changed, but it had very little sequencing coverage. Across all six replicates there were only ",
                    total_count,
                    " total counts, and the gene failed the coverage filter. With so little information, neither method had enough evidence to call the gene significantly differentially expressed, so it was classified as a false negative."
                )
            ),
            out
        )
    }
}

writeLines(
    c(
        "",
        "These examples show two different reasons for errors. A false positive can occur when random sampling makes an unchanged gene appear different between groups. False negatives can occur when a true expression change is obscured by biological/sampling variability or when read coverage is too low to provide sufficient statistical evidence."
    ),
    out
)

close(out)

cat("Created results/fp_fn_examples.md\n")
