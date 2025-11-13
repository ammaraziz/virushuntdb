# fetch genome sequence from NCBI
# -----------------------------------------------------
rule get_genomes:
    input:
        accession="{accession}"
    output:
        zipped=temp(RESULTS / "{accession}" / "dataset.zip")
        genomes=RESULTS / "{accession}" / "genomes.fasta",
    conda:
        "../envs/get_genomess.yaml"
    message:
        """--- Downloading genome sequence."""
    log:
        RESULTS / "logs" / "download_{accession}.log",
    shell:"""
    datasets download virus genome taxon {input.accession:q} --filename  {output.zipped} 2>> {log}

    unzip -p {output.zipped} ncbi_dataset/data/genomic.fna > {output.genomes} 2>> {log}
    """

# Filter genomes by length
# -----------------------------------------------------
rule filter_genomes:
    input:
        rules.get_genomes.input.accession
    output:
        genomes=RESULTS / "{accession}" / "genomes.filtered.fasta"
    params:
        ratio=0.90
    threads: 4
    conda:
        "../envs/utils.yaml"
    message:
        """--- Filtering and cleaning genomes"""
    log:
        RESULTS / "logs" / "clean_{accession}.log",
    shell:"""
    # calc length of NC_ reference genome if present
    LIMIT=$(seqkit grep -r -p "NC_" genomes.fasta \
    | seqkit stats --all --tabular \
    | csvtk -t mutate3 --name "lower" --expression '($max_len * {params.ratio})' \
    | csvtk -t round -f "lower" --decimal-width 0 \
    | csvtk -t cut -f "lower" --delete-header \
    ) 2>> {log}

    seqkit seq \
    {input} \
    --threads {threads} \
    --remove-gaps \
    --gap-letters "N-." \
    --min-len $LIMIT \
    --out-file {output.genomes} 2>> {log}
    """

# Extract reference
# assumed that the reference is present in the ICTV VMR list
# -----------------------------------------------------
rule extract_reference:
    input:
        rules.get_genomes.input.accession
    output:
        genomes=RESULTS / "{accession}" / "genomes.filtered.noref.fasta",
        reference=RESULTS / "{accession}" / "reference.fasta"
    params:
        reference="NC_003243.1" # fix later to replace with wildcard
    threads: 4
    conda:
        "../envs/utils.yaml"
    message:
        """--- Extract reference for alignment"""
    log:
        RESULTS / "logs" / "get_reference_{accession}.log",
    shell:"""
    seqkit grep --by-name \
    --invert-match \
    --pattern {params.reference} \
    --out-file {output.genomes}

    seqkit grep --by-name \
    --pattern {params.reference} \
    --out-file {output.reference}
    """

# Align sequences - mimic augur align against reference
# -----------------------------------------------------
rule nextalign:
    input:
       genomes=rules.extract_reference.output.genomes,
       reference=rules.extract_reference.output.reference,
    output:
        tmp=temp(RESULTS / "{accession}" / "genomes.filtered.aligned.noclean.fasta")
        sequences=RESULTS / "{accession}" / "genomes.filtered.aligned.fasta"
    threads: 9
    conda:
        "../envs/nextclade.yaml"
    message:
        """--- Aligning sequences to reference"""
    log:
        RESULTS / "logs" / "align_{accession}.log",
    shell:"""
    nextclade run \
    --retry-reverse-complement \
    --input-ref {input.reference} \
    --output-fasta {output.tmp} \
    {input.genomes}

    goalign clean \
    --cutoff 0 \
    --align {output.tmp} \
    --output {output.genomes}
    """

# Create phylotree
# -----------------------------------------------------
rule fasttree:
    input:
        alignment=rules.nextalign.output.sequences,
    output:
        tree=RESULTS / "{accession}" / "tree.nwk"
    shadow: "shallow"
    threads: 5
    conda:
        "../envs/iqtree.yaml"
    message:
        """--- Aligning sequences to reference"""
    log:
        RESULTS / "logs" / "tree_{accession}.log",
    shell:"""
    iqtree -s {input.alignemnt} -m GTR -fast -pre tree
    mv tree.treefile {output.tree}
    """

# Pick clusters
# -----------------------------------------------------
rule clustertree:
    input:
        tree=rules.fasttree.output.tree,
    output:
        clusters=RESULTS / "{accession}" / "clusters.tsv",
        representatives=RESULTS / "{access}" / "clusters.uniq.tsv"
    params:
        method="root_dist", 
        threshold=0.045, # recommended by author
    threads: 5
    conda:
        "../envs/clustertree.yaml"
    message:
        """--- Picking clusters from tree"""
    log:
        RESULTS / "logs" / "clusters_{accession}.log",
    shell:"""
    TreeCluster.py \
    --input {input.tree} \
    --threshold {params.threshold} \
    --method {params.method} > {output.clusters}

    csvtk -t sort -k SequenceName {output.clusters} \
    | csvtk -t uniq -f ClusterNumber \
    | csvtk -t cut -f SequenceName --delete-header > {output.representatives}
    """

# mmseqs2 clusters
# -----------------------------------------------------
rule mmseq:
    input:
        sequences=rules.get_genomes.input.accession,
    output:
        clusters=RESULTS / "{accession}" / "clusters.tsv",
        representatives=RESULTS / "{access}" / "clusters.uniq.tsv"
    params:
        method="root_dist", 
        threshold=0.045, # recommended by author
    threads: 5
    conda:
        "../envs/clustertree.yaml"
    message:
        """--- Picking clusters from tree"""
    log:
        RESULTS / "logs" / "clusters_{accession}.log",
    shell:"""