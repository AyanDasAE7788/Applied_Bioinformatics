#!/usr/bin/env Rscript

# ============================================================
# Week 13
# Compare known simulation truth to differential-expression
# results from edgeR and DESeq2.
# ============================================================

args <- commandArgs(trailingOnly = TRUE)

results_dir <- if (
    length(args) >= 1
) args[1] else "results"

methods <- c(
    "edgeR",
    "deseq2"
)

safe_divide <- function(a, b) {

    if (b == 0) {
        return(NA_real_)
    }

    a / b
}

evaluate_method <- function(
    file,
    method_name
) {

    x <- read.csv(
        file,
        stringsAsFactors = FALSE,
        check.names = FALSE
    )

    required <- c(
        "gene",
        "status",
        "filter",
        "FDR"
    )

    missing_columns <- setdiff(
        required,
        names(x)
    )

    if (
        length(missing_columns) > 0
    ) {

        stop(
            paste(
                "Missing columns:",
                paste(
                    missing_columns,
                    collapse = ", "
                )
            )
        )
    }

    # Treat missing FDR as non-significant
    x$FDR[
        is.na(x$FDR)
    ] <- 1

    changed <-
        x$status == "changed"

    significant <-
        x$FDR < 0.05

    x$class <- ifelse(
        changed & significant,
        "TP",
        ifelse(
            !changed & significant,
            "FP",
            ifelse(
                !changed & !significant,
                "TN",
                "FN"
            )
        )
    )

    TP <- sum(
        x$class == "TP"
    )

    FP <- sum(
        x$class == "FP"
    )

    TN <- sum(
        x$class == "TN"
    )

    FN <- sum(
        x$class == "FN"
    )

    accuracy <- safe_divide(
        TP + TN,
        TP + FP + TN + FN
    )

    precision <- safe_divide(
        TP,
        TP + FP
    )

    recall <- safe_divide(
        TP,
        TP + FN
    )

    specificity <- safe_divide(
        TN,
        TN + FP
    )

    f1 <- safe_divide(
        2 * TP,
        2 * TP + FP + FN
    )

    observed_fdr <- safe_divide(
        FP,
        TP + FP
    )

    mcc_denominator <- sqrt(
        as.numeric(TP + FP) *
        (TP + FN) *
        (TN + FP) *
        (TN + FN)
    )

    MCC <- if (
        mcc_denominator == 0
    ) {
        NA_real_
    } else {
        (
            TP * TN -
            FP * FN
        ) /
        mcc_denominator
    }

    summary <- data.frame(
        Method = method_name,
        TP = TP,
        FP = FP,
        TN = TN,
        FN = FN,
        Filter_pass = sum(
            x$filter == "pass"
        ),
        Filter_fail = sum(
            x$filter == "fail"
        ),
        Accuracy = accuracy,
        Precision = precision,
        Recall = recall,
        Specificity = specificity,
        F1 = f1,
        MCC = MCC,
        Observed_FDR = observed_fdr,
        stringsAsFactors = FALSE
    )

    errors <- x[
        x$class %in% c(
            "FP",
            "FN"
        ),
    ]

    errors$Method <- method_name

    list(
        summary = summary,
        results = x,
        errors = errors
    )
}

# ------------------------------------------------------------
# Evaluate both methods
# ------------------------------------------------------------

edge <- evaluate_method(
    file.path(
        results_dir,
        "edgeR.csv"
    ),
    "edgeR"
)

deseq <- evaluate_method(
    file.path(
        results_dir,
        "deseq2.csv"
    ),
    "DESeq2"
)

summary_table <- rbind(
    edge$summary,
    deseq$summary
)

write.csv(
    summary_table,
    file.path(
        results_dir,
        "evaluation_summary.csv"
    ),
    row.names = FALSE,
    quote = FALSE
)

misclassified <- rbind(
    edge$errors,
    deseq$errors
)

write.csv(
    misclassified,
    file.path(
        results_dir,
        "misclassified_genes.csv"
    ),
    row.names = FALSE,
    quote = FALSE
)

# ------------------------------------------------------------
# Compare edgeR and DESeq2 calls
# ------------------------------------------------------------

edge_calls <- data.frame(
    gene = edge$results$gene,
    edgeR_significant =
        edge$results$FDR < 0.05
)

deseq_calls <- data.frame(
    gene = deseq$results$gene,
    DESeq2_significant =
        deseq$results$FDR < 0.05
)

comparison <- merge(
    edge_calls,
    deseq_calls,
    by = "gene"
)

comparison$agreement <- ifelse(
    comparison$edgeR_significant ==
    comparison$DESeq2_significant,
    "same",
    "different"
)

write.csv(
    comparison,
    file.path(
        results_dir,
        "method_comparison.csv"
    ),
    row.names = FALSE,
    quote = FALSE
)

# ------------------------------------------------------------
# Print results
# ------------------------------------------------------------

cat(
    "\n========================================\n"
)

cat(
    "WEEK 13 EVALUATION SUMMARY\n"
)

cat(
    "========================================\n\n"
)

print(
    summary_table,
    row.names = FALSE
)

cat(
    "\nMethod agreement:\n"
)

cat(
    "Same decision:",
    sum(
        comparison$agreement == "same"
    ),
    "\n"
)

cat(
    "Different decision:",
    sum(
        comparison$agreement == "different"
    ),
    "\n"
)

for (
    method in c(
        "edgeR",
        "DESeq2"
    )
) {

    cat(
        "\n----------------------------------------\n"
    )

    cat(
        method,
        "example false positives / negatives\n"
    )

    cat(
        "----------------------------------------\n"
    )

    tmp <- misclassified[
        misclassified$Method == method,
        c(
            "gene",
            "status",
            "filter",
            "mean_A",
            "mean_B",
            "log2FC",
            "FDR",
            "class"
        )
    ]

    print(
        head(
            tmp,
            8
        ),
        row.names = FALSE
    )
}

