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