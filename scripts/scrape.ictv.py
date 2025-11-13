import requests
import pandas as pd

# https://ictv.global/virus-properties?
# webform_submission_value_2=All # dna/rna/rt - All,1,2,3
# webform_submission_value_7=All # double or single All,1,2
# webform_submission_value=All # envlope All,1,2,3,4
# webform_submission_value_5=All # many, ignore
# webform_submission_value_4=6 # host selection All,1,2,3,4,5,6,7
# webform_submission_value_1=&items_per_page=All

def create_ictv_url(
	base = "https://ictv.global/virus-properties?",
	molecule_type = "All", # controls dna/rna/rt - All,1,2,3
	strandedness = "All", # double or single All,1,2
	envelope = "All", # All,1,2,3,4
	host = "All", #  Any,1-Archaea,2-Bacteria,3-Fungi,4-Invertebrates,5-Plants,6-Protists,7-Vertebrates
	):
	
	molecule_type_url = "webform_submission_value_2="
	strandedness_url = "webform_submission_value_7="
	envelope_url = "webform_submission_value="
	host_url = "webform_submission_value_4="

	ignored = "webform_submission_value_5=All"
	end = "webform_submission_value_1=&items_per_page=All"
	separator = "&"

	url = "".join([
	base,
	molecule_type_url, str(molecule_type), separator,
	strandedness_url, str(strandedness), separator,
	envelope_url, str(envelope), separator,
	ignored, separator,
	host_url, str(host), separator,
	end
	])
	return(url)

url = create_ictv_url(host=7)
html = requests.get(url).content
df_list = pd.read_html(html)
df = df_list[0]
df.to_csv('my_data.csv', index=False)