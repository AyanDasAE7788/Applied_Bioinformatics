#!/usr/bin/env python3

import gzip
import sys

FASTA = "reference/GCF_000005845.2_ASM584v2_genomic.fna"
GFF = "annotation/GCF_000005845.2_ASM584v2_genomic.gff.gz"
VCF = "variants/multisample_variants.vcf.gz"
OUT = "annotation/coding_variant_effects.tsv"

CODON_TABLE = {
    "TTT":"F","TTC":"F","TTA":"L","TTG":"L",
    "TCT":"S","TCC":"S","TCA":"S","TCG":"S",
    "TAT":"Y","TAC":"Y","TAA":"*","TAG":"*",
    "TGT":"C","TGC":"C","TGA":"*","TGG":"W",

    "CTT":"L","CTC":"L","CTA":"L","CTG":"L",
    "CCT":"P","CCC":"P","CCA":"P","CCG":"P",
    "CAT":"H","CAC":"H","CAA":"Q","CAG":"Q",
    "CGT":"R","CGC":"R","CGA":"R","CGG":"R",

    "ATT":"I","ATC":"I","ATA":"I","ATG":"M",
    "ACT":"T","ACC":"T","ACA":"T","ACG":"T",
    "AAT":"N","AAC":"N","AAA":"K","AAG":"K",
    "AGT":"S","AGC":"S","AGA":"R","AGG":"R",

    "GTT":"V","GTC":"V","GTA":"V","GTG":"V",
    "GCT":"A","GCC":"A","GCA":"A","GCG":"A",
    "GAT":"D","GAC":"D","GAA":"E","GAG":"E",
    "GGT":"G","GGC":"G","GGA":"G","GGG":"G",
}

COMP = str.maketrans("ACGT", "TGCA")


def revcomp(seq):
    return seq.translate(COMP)[::-1]


def parse_attrs(text):
    d = {}
    for x in text.split(";"):
        if "=" in x:
            k, v = x.split("=", 1)
            d[k] = v
    return d


# --------------------------------------------------
# Read reference FASTA
# --------------------------------------------------

seqs = {}
name = None
chunks = []

with open(FASTA) as f:
    for line in f:
        line = line.strip()
        if line.startswith(">"):
            if name is not None:
                seqs[name] = "".join(chunks).upper()
            name = line[1:].split()[0]
            chunks = []
        else:
            chunks.append(line)

if name is not None:
    seqs[name] = "".join(chunks).upper()


# --------------------------------------------------
# Read CDS annotations
# --------------------------------------------------

cds_features = []

with gzip.open(GFF, "rt") as f:
    for line in f:
        if line.startswith("#"):
            continue

        fields = line.rstrip().split("\t")
        if len(fields) != 9:
            continue

        chrom, source, feature, start, end, score, strand, phase, attrs = fields

        if feature != "CDS":
            continue

        # Keep simple complete CDS features.
        # E. coli protein-coding CDS records are generally phase 0.
        if phase not in ("0", "."):
            continue

        a = parse_attrs(attrs)

        cds_features.append({
            "chrom": chrom,
            "start": int(start),
            "end": int(end),
            "strand": strand,
            "gene": a.get("gene", ""),
            "locus_tag": a.get("locus_tag", ""),
            "product": a.get("product", ""),
        })


# --------------------------------------------------
# Read VCF and annotate biallelic SNPs
# --------------------------------------------------

sample_names = []

header = [
    "CHROM",
    "POS",
    "REF",
    "ALT",
    "gene",
    "locus_tag",
    "product",
    "strand",
    "codon_number",
    "ref_codon",
    "alt_codon",
    "ref_aa",
    "alt_aa",
    "effect",
]

rows = []

with gzip.open(VCF, "rt") as f:
    for line in f:

        if line.startswith("##"):
            continue

        if line.startswith("#CHROM"):
            cols = line.rstrip().split("\t")
            sample_names = cols[9:]
            continue

        fields = line.rstrip().split("\t")

        chrom = fields[0]
        pos = int(fields[1])
        ref = fields[3]
        alt = fields[4]

        # Only simple biallelic SNPs for codon-effect analysis
        if len(ref) != 1 or len(alt) != 1 or "," in alt:
            continue

        fmt = fields[8].split(":") if len(fields) > 8 else []
        sample_fields = fields[9:]

        sample_gt = {}

        if "GT" in fmt:
            gt_i = fmt.index("GT")
            for sample, data in zip(sample_names, sample_fields):
                parts = data.split(":")
                sample_gt[sample] = parts[gt_i] if gt_i < len(parts) else "."
        else:
            for sample in sample_names:
                sample_gt[sample] = "."

        for cds in cds_features:

            if cds["chrom"] != chrom:
                continue

            if not (cds["start"] <= pos <= cds["end"]):
                continue

            genome_seq = seqs[chrom]
            cds_seq = genome_seq[cds["start"] - 1 : cds["end"]]

            if cds["strand"] == "+":
                coding_seq = cds_seq
                coding_index = pos - cds["start"]
                alt_coding_base = alt

            else:
                coding_seq = revcomp(cds_seq)
                coding_index = cds["end"] - pos
                alt_coding_base = alt.translate(COMP)

            codon_start = (coding_index // 3) * 3
            codon_number = coding_index // 3 + 1

            ref_codon = coding_seq[codon_start:codon_start + 3]

            if len(ref_codon) != 3:
                continue

            position_in_codon = coding_index % 3

            alt_codon_list = list(ref_codon)
            alt_codon_list[position_in_codon] = alt_coding_base
            alt_codon = "".join(alt_codon_list)

            ref_aa = CODON_TABLE.get(ref_codon, "?")
            alt_aa = CODON_TABLE.get(alt_codon, "?")

            if ref_aa == alt_aa:
                effect = "synonymous"
            elif alt_aa == "*" and ref_aa != "*":
                effect = "stop_gained"
            elif ref_aa == "*" and alt_aa != "*":
                effect = "stop_lost"
            else:
                effect = "missense"

            row = [
                chrom,
                str(pos),
                ref,
                alt,
                cds["gene"],
                cds["locus_tag"],
                cds["product"],
                cds["strand"],
                str(codon_number),
                ref_codon,
                alt_codon,
                ref_aa,
                alt_aa,
                effect,
            ]

            row += [sample_gt[s] for s in sample_names]
            rows.append(row)


with open(OUT, "w") as out:
    out.write("\t".join(header + sample_names) + "\n")
    for row in rows:
        out.write("\t".join(row) + "\n")

print(f"CDS features read: {len(cds_features)}")
print(f"Coding SNP consequences written: {len(rows)}")
print(f"Output: {OUT}")