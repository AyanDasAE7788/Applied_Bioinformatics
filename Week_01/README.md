# Week_01 - Computer Setup

## Code Editor

I chose Visual Studio Code  as my code editor.

## Samtools Version

First, I activated the bioinfo environment:

```bash
conda activate bioinfo
```

I have also tried:
```bash
bioinfo
```

And it activated the bioinfo environment as well. Then I checked the location of samtools with:

```bash
which samtools
```

The output was:

```text
/home/ae7788/micromamba/envs/bioinfo/bin/samtools
```

Then I asked for the samtools version using:

```bash
samtools --version | head -n 1
```

And I got this:

```text
samtools 1.24
```

## Creating Nested Directories

I created a nested directory structure using:

```bash
mkdir -p data/raw data/processed results/figures
```

Then I checked the directory using:

```bash
find .
```

And the outcome was:

```text
.
./results
./results/figures
./README.md
./data
./data/processed
./data/raw
```

Therefore, the resulting structure contains:

```text
data/
├── raw/
└── processed/
results/
└── figures/
```

## Creating Files in Different Directories

I created three text files with:

```bash
touch data/raw/sequences.txt
touch data/processed/filtered_sequences.txt
touch results/figures/plot.txt
```

Then I added sample text to one file:

```bash
echo "Example sequence data" > data/raw/sequences.txt
```

## Accessing a File with a Relative Path

From the Week_01 directory:

```bash
cat data/raw/sequences.txt
```

I got the output as I wrote into the text file:

```text
Example sequence data
```

## Accessing a File with an Absolute Path

I used the following command:

```bash
cat /home/ae7788/Applied_Bioinformatics/Week_01/data/raw/sequences.txt
```

And I got the same output:

```text
Example sequence data
```

**Thanks. That's all for today.**