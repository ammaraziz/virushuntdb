# import basic packages
import pandas as pd
from snakemake.utils import validate
from pathlib import Path

# read sample sheet
samples = (
    pd.read_csv(config["samplesheet"], sep="\t", dtype={"sample": str})
    .set_index("sample", drop=False)
    .sort_index()
)

#print(samples.loc['sample1', 'read1'])


# validate sample sheet and config file
validate(samples, schema="../../config/schemas/samples.schema.yaml")
validate(config, schema="../../config/schemas/config.schema.yaml")
