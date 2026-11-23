#!/usr/bin/env Rscript

# ============================================================
# Week 13 RNA-seq simulation
# Simulate counts with known changed/unchanged genes,
# then analyze using edgeR and DESeq2.
# ============================================================

args <- commandArgs(trailingOnly = TRUE)

seed <- if (length(args) >= 1) as.integer(args[1]) else 13
out_dir <- if (length(args) >= 2) args[2] else "results"

dir.create(
    out_dir,
    recursive = TRUE,
    showWarnings = FALSE
)

suppressPackageStartupMessages({
    library(edgeR)
    library(DESeq2)
})

set.seed(seed)

# ------------------------------------------------------------
# Simulation settings
# ------------------------------------------------------------

n_genes <- 2000
n_rep <- 3

genes <- sprintf(
    "gene_%04d",
    seq_len(n_genes)
)

samples <- c(
    "A_Rep1",
    "A_Rep2",
    "A_Rep3",
    "B_Rep1",
    "B_Rep2",
    "B_Rep3"
)

condition <- factor(
    rep(
        c("A", "B"),
        each = n_rep
    ),
    levels = c("A", "B")
)

# 20% of genes are truly changed
n_changed <- round(
    0.20 * n_genes
)

changed_genes <- sample(
    seq_len(n_genes),
    n_changed,
    replace = FALSE
)

status <- rep(
    "unchanged",
    n_genes
)

status[changed_genes] <- "changed"

# Baseline expression levels
base_mean <- exp(
    rnorm(
        n_genes,
        mean = log(50),
        sd = 1.1
    )
)

# True log2 fold changes
true_log2FC <- rep(
    0,
    n_genes
)

true_log2FC[changed_genes] <-
    sample(
        c(-1, 1),
        n_changed,
        replace = TRUE
    ) *
    runif(
        n_changed,
        min = 1,
        max = 2
    )

# Gene-specific dispersion
dispersion <-
    0.08 +
    4 / (base_mean + 20)

# Small differences in sequencing depth
library_factor <- exp(
    rnorm(
        length(samples),
        mean = 0,
        sd = 0.08
    )
)

# ------------------------------------------------------------
# Simulate negative-binomial RNA-seq counts
# ------------------------------------------------------------

counts <- matrix(
    0,
    nrow = n_genes,
    ncol = length(samples),
    dimnames = list(
        genes,
        samples
    )
)

for (j in seq_along(samples)) {

    mu <- base_mean *
          library_factor[j]

    if (condition[j] == "B") {
        mu <- mu *
              2^true_log2FC
    }

    counts[, j] <- rnbinom(
        n_genes,
        mu = mu,
        size = 1 / dispersion
    )
}

# ------------------------------------------------------------
# Coverage filter
# ------------------------------------------------------------

filter_pass <-
    rowSums(counts) >= 20 &
    rowSums(counts >= 5) >= 2

filter_status <- ifelse(
    filter_pass,
    "pass",
    "fail"
)

mean_A <- rowMeans(
    counts[, condition == "A", drop = FALSE]
)

mean_B <- rowMeans(
    counts[, condition == "B", drop = FALSE]
)

# Save simulated counts and known truth
simulation <- data.frame(
    gene = genes,
    status = status,
    filter = filter_status,
    true_log2FC = true_log2FC,
    mean_A = mean_A,
    mean_B = mean_B,
    counts,
    check.names = FALSE
)

write.csv(
    simulation,
    file.path(
        out_dir,
        "simulation_counts.csv"
    ),
    row.names = FALSE,
    quote = FALSE
)

cat(
    "Simulation complete.\n"
)

cat(
    "Total genes:",
    n_genes,
    "\n"
)

cat(
    "Changed genes:",
    sum(status == "changed"),
    "\n"
)

cat(
    "Unchanged genes:",
    sum(status == "unchanged"),
    "\n"
)

cat(
    "Filter pass:",
    sum(filter_pass),
    "\n"
)

cat(
    "Filter fail:",
    sum(!filter_pass),
    "\n\n"
)

# ============================================================
# edgeR
# ============================================================

cat(
    "Running edgeR...\n"
)

pass_counts <- counts[
    filter_pass,
    ,
    drop = FALSE
]

y <- DGEList(
    counts = pass_counts,
    group = condition
)

y <- normLibSizes(y)

y <- estimateDisp(
    y
)

edge_test <- exactTest(
    y,
    pair = c(
        "A",
        "B"
    )
)

edge_table <- topTags(
    edge_test,
    n = Inf,
    sort.by = "none"
)$table

edgeR_result <- data.frame(
    gene = genes,
    status = status,
    filter = filter_status,
    mean_A = mean_A,
    mean_B = mean_B,
    log2FC = NA_real_,
    PValue = NA_real_,
    FDR = 1,
    stringsAsFactors = FALSE
)

edge_match <- match(
    rownames(edge_table),
    edgeR_result$gene
)

edgeR_result$log2FC[edge_match] <-
    edge_table$logFC

edgeR_result$PValue[edge_match] <-
    edge_table$PValue

edgeR_result$FDR[edge_match] <-
    edge_table$FDR

write.csv(
    edgeR_result,
    file.path(
        out_dir,
        "edgeR.csv"
    ),
    row.names = FALSE,
    quote = FALSE
)

# ============================================================
# DESeq2
# ============================================================

cat(
    "Running DESeq2...\n"
)

col_data <- data.frame(
    condition = condition,
    row.names = samples
)

dds <- DESeqDataSetFromMatrix(
    countData = pass_counts,
    colData = col_data,
    design = ~ condition
)

dds <- DESeq(
    dds,
    quiet = TRUE
)

deseq_table <- results(
    dds,
    contrast = c(
        "condition",
        "B",
        "A"
    ),
    independentFiltering = FALSE
)

deseq_table <- as.data.frame(
    deseq_table
)

DESeq2_result <- data.frame(
    gene = genes,
    status = status,
    filter = filter_status,
    mean_A = mean_A,
    mean_B = mean_B,
    log2FC = NA_real_,
    PValue = NA_real_,
    FDR = 1,
    stringsAsFactors = FALSE
)

deseq_match <- match(
    rownames(deseq_table),
    DESeq2_result$gene
)

DESeq2_result$log2FC[deseq_match] <-
    deseq_table$log2FoldChange

DESeq2_result$PValue[deseq_match] <-
    deseq_table$pvalue

DESeq2_result$FDR[deseq_match] <-
    deseq_table$padj

# Any NA adjusted p-value is treated as non-significant
DESeq2_result$FDR[
    is.na(DESeq2_result$FDR)
] <- 1

write.csv(
    DESeq2_result,
    file.path(
        out_dir,
        "deseq2.csv"
    ),
    row.names = FALSE,
    quote = FALSE
)

cat(
    "\nSimulation and differential expression complete.\n"
)

cat(
    "Outputs:\n"
)

cat(
    file.path(
        out_dir,
        "edgeR.csv"
    ),
    "\n"
)

cat(
    file.path(
        out_dir,
        "deseq2.csv"
    ),
    "\n"
)

