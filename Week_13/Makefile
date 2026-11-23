SHELL := /bin/bash
.RECIPEPREFIX := >

SEED := 13
RESULTS := results

.PHONY: all simulate evaluate rerun clean check-tools

all: evaluate

check-tools:
> @Rscript -e 'stopifnot(requireNamespace("edgeR", quietly=TRUE)); stopifnot(requireNamespace("DESeq2", quietly=TRUE)); cat("edgeR and DESeq2 found.\n")'

simulate:
> mkdir -p $(RESULTS)
> Rscript src/simulate_and_de.R $(SEED) $(RESULTS)

evaluate: simulate
> Rscript src/evaluate_results.R $(RESULTS)

rerun:
> rm -rf results_rerun
> mkdir -p results_rerun
> Rscript src/simulate_and_de.R 1313 results_rerun
> Rscript src/evaluate_results.R results_rerun

clean:
> rm -rf results results_rerun
