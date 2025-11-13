# VirusHuntDB
A drop in, customizable, replacement for Virosaurus

# Planning

How was Virosaurus created?

#### QC:
1. Viral sequences were downloaded from INSDC
	- Sequences were filtered by removing all obviously incomplete sequences through keywords like “partial”, “incomplete”, “near complete”, etc. 
	- A range of sizes was manually curated for each virus using all available data in INSDC to assess completeness (manually??)
	- The sequences were separated into non-segmented and segmented genomes. 
2. Sequences were filtered using the Expasy ViralZone list of viruses that infect Eukaryotes
3. Sequences divided into vertebrate, plant and other eukaryotes, rest were descarded
4. Sequences were labelled using ICTV species names
5. Removal of sequences with too many “N”s (more than 10%) or at least one gap annotation of unknown length.
6. Not applicable to VirusHuntDB: Non-viral elements, like vectors or recombined oncogenes were removed by the application of keywords filtering.
 
#### For segmented viruses:
1. All segmented virus sequences were clustered and the segment name was identified by checking for similarity against UniProt (BLAST) 
2. All segments have been processed exactly as monopartite genomes for quality and completeness. 
3. Once all segment names were identified by sequence similarity, their completeness was estimated by comparing to a matrix of complete segment size ranges for each genus. Size data were established manually for each virus genus using INSDC data.
4. Mutli-species clusters were checked manually. All names were reported in the FASTA header representing the cluster.

#### Clinical Annotation
1. Manually curated set of viruses were labelled as 'clinical typing', with some viruses labelled as low or high risk.
	- Norwalk, Dengue, and Hepatitis C viruses
	- Enterovirus 71, Enterovirus 68, low-risk or high risk HPVs, Polio or non-polio enterovirus C, and novel or classical for mamastrovirus

#### Clustering

1. Clustering was performed with CD-HIT at 90% and 98% identity.
2. For herpesvirid and poxvirid, virus genes were to speed up clustering
3. Clusters were then controlled for size homogeneity (cut-off 80%) and checked if they referred to a single species. 


### Proposed methodology for VirusHuntDB

Virosaurus uses a 'top-down' approach: AllSequences->filter->cluster. VirusHuntDB will take a bottom-up approach: VirusSequences->Curate->Filter->Cluster

Non-segmented viruses:
1. Extract list of viruses which infect plant or vertebrate etc from ICTV Virus Properties tables.
2. Match virus family to the VMR list, extract ncbi taxon id
3. Download examplar genome and annotation to use as reference
4. Align with Nextclade sequences to examplar genome
5. Filter genomes which are near-complete (95%) compared to reference
6. Cluster with mmseq2 with `linclust`

Segmented viruses:
1. 


### Resources

- [ICTV VMR contains](https://ictv.global/vmr) a complete list of examplar viruses and ncbi taxon ids
- [ICTV Virus Properties table](https://ictv.global/virus-properties) for extracting viruses that infect specific hosts
- [Expasy Viral Zone](https://viralzone.expasy.org/655) used by Virosaurus