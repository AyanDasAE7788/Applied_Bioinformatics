#!/usr/bin/env Rscript

# ------------------------------------------------------------
# Week 12
# Generate transcript-level and gene-level count matrices
# from Salmon transcript quantification.
# ------------------------------------------------------------

args <- commandArgs(trailingOnly = TRUE)

quant_dir <- if (length(args) >= 1) args[1] else "quant"
gtf_file  <- if (length(args) >= 2) args[2] else "../Week_11/gtf/chr22.gtf"
out_dir   <- if (length(args) >= 3) args[3] else "results"

samples <- c(
    "HBR_Rep1",
    "HBR_Rep2",
    "HBR_Rep3",
    "UHR_Rep1",
    "UHR_Rep2",
    "UHR_Rep3"
)

dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

# ------------------------------------------------------------
# Read transcript-to-gene information from GTF
# ------------------------------------------------------------

cat("Reading GTF annotation...\n")

gtf <- readLines(gtf_file)

transcript_lines <- grep(
    "\ttranscript\t",
    gtf,
    value = TRUE
)

extract_attribute <- function(lines, key) {

    pattern <- paste0(key, ' "([^"]+)"')

    matches <- regexec(pattern, lines)
    values <- regmatches(lines, matches)

    vapply(
        values,
        function(x) {
            if (length(x) >= 2) {
                x[2]
            } else {
                NA_character_
            }
        },
        character(1)
    )
}

annotation <- data.frame(
    transcript_id = extract_attribute(transcript_lines, "transcript_id"),
    gene_id       = extract_attribute(transcript_lines, "gene_id"),
    gene_name     = extract_attribute(transcript_lines, "gene_name"),
    stringsAsFactors = FALSE
)

annotation <- annotation[
    !is.na(annotation$transcript_id),
]

annotation <- unique(annotation)

cat(
    "Transcript annotations:",
    nrow(annotation),
    "\n"
)

# ------------------------------------------------------------
# Read Salmon transcript counts
# ------------------------------------------------------------

cat("Reading Salmon quantifications...\n")

count_tables <- list()

for (sample in samples) {

    quant_file <- file.path(
        quant_dir,
        sample,
        "quant.sf"
    )

    if (!file.exists(quant_file)) {
        stop(
            paste(
                "Missing Salmon file:",
                quant_file
            )
        )
    }

    q <- read.delim(
        quant_file,
        header = TRUE,
        stringsAsFactors = FALSE,
        check.names = FALSE
    )

    q <- q[, c("Name", "NumReads")]

    names(q) <- c(
        "transcript_id",
        sample
    )

    count_tables[[sample]] <- q
}

# ------------------------------------------------------------
# Merge transcript counts from all samples
# ------------------------------------------------------------

transcript_counts <- Reduce(
    function(x, y) {
        merge(
            x,
            y,
            by = "transcript_id",
            all = TRUE,
            sort = FALSE
        )
    },
    count_tables
)

for (sample in samples) {
    transcript_counts[[sample]][
        is.na(transcript_counts[[sample]])
    ] <- 0
}

# Add gene annotation
transcript_matrix <- merge(
    annotation,
    transcript_counts,
    by = "transcript_id",
    all.y = TRUE,
    sort = FALSE
)

# If any transcript lacks annotation, retain an identifier
missing_gene <- is.na(transcript_matrix$gene_id)

transcript_matrix$gene_id[missing_gene] <-
    transcript_matrix$transcript_id[missing_gene]

missing_name <- is.na(transcript_matrix$gene_name)

transcript_matrix$gene_name[missing_name] <-
    transcript_matrix$gene_id[missing_name]

# Reorder columns
transcript_matrix <- transcript_matrix[
    ,
    c(
        "transcript_id",
        "gene_id",
        "gene_name",
        samples
    )
]

# Sort for easier inspection
transcript_matrix <- transcript_matrix[
    order(
        transcript_matrix$gene_name,
        transcript_matrix$transcript_id
    ),
]

# ------------------------------------------------------------
# Write transcript-level count matrix
# ------------------------------------------------------------

transcript_output <- file.path(
    out_dir,
    "transcript_count_matrix.csv"
)

write.csv(
    transcript_matrix,
    transcript_output,
    row.names = FALSE,
    quote = FALSE
)

cat(
    "Transcript-level matrix written to:",
    transcript_output,
    "\n"
)

# ------------------------------------------------------------
# Generate gene-level matrix
#
# Gene count = sum of NumReads from all transcripts
# belonging to that gene.
# ------------------------------------------------------------

cat("Summarizing transcript counts to genes...\n")

gene_matrix <- aggregate(
    transcript_matrix[, samples, drop = FALSE],
    by = list(
        gene_id = transcript_matrix$gene_id,
        gene_name = transcript_matrix$gene_name
    ),
    FUN = function(x) {
        sum(x, na.rm = TRUE)
    }
)

gene_matrix <- gene_matrix[
    order(gene_matrix$gene_name),
]

gene_output <- file.path(
    out_dir,
    "gene_count_matrix.csv"
)

write.csv(
    gene_matrix,
    gene_output,
    row.names = FALSE,
    quote = FALSE
)

cat(
    "Gene-level matrix written to:",
    gene_output,
    "\n"
)

# ------------------------------------------------------------
# Summary
# ------------------------------------------------------------

cat("\n")
cat("========================================\n")
cat("COUNT MATRIX SUMMARY\n")
cat("========================================\n")

cat(
    "Transcript rows:",
    nrow(transcript_matrix),
    "\n"
)

cat(
    "Gene rows:",
    nrow(gene_matrix),
    "\n"
)

cat(
    "Samples:",
    length(samples),
    "\n"
)

cat("\nSelected Week 11 genes:\n")

selected <- gene_matrix[
    gene_matrix$gene_name %in% c(
        "GRK3",
        "SGSM1"
    ),
]

print(
    selected,
    row.names = FALSE
)

cat("\nDone.\n")
