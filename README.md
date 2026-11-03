# Convert MIMIC-IV to OMOP Format with this Conversion Tool

Use DBT to convert the MIMIC-IV dataset to OMOP CDM format, with an optional extension for MIMIC-CXR chest X-ray imaging data following the [OHDSI Medical Imaging CDM (MI-CDM)](https://ohdsi.github.io/CommonDataModel/) specification.

## Citation and Reference:

Please cite this work if you fine the pipeline useful:

```
@inproceedings{sutton2026fast,
  title={Fast, Accurate, and Local Conversion of MIMIC-IV to OMOP with DBT},
  author={Sutton, Adam and Moller-Grell, Niko and Searle, Thomas and Dobson, Richard},
  booktitle={BioNLP 2026},
  pages={992--996},
  year={2026}
}
```

## Prerequisites

## Requirements

>= 16GB RAM
>= 200GB Hard Disk (core MIMIC-IV; add ~75 MB for MIMIC-CXR metadata)

## Environment

Run the following in the project root to set up virtual environment with `uv`:

```
uv sync
```

## Step by Step Guide:

### 1. Download Vocabularies

Download the required vocabularies [here](https://athena.ohdsi.org/vocabulary/list).

### 2. Download The MIMIC-IV Dataset

Create an account at [PhysioNet](https://physionet.org/). Complete the process to get credentialled access [here](https://physionet.org/settings/credentialing/).

Run the following to download the MIMIC-IV dataset with your PhysioNet credentials:

```
wget -r -N -c -np --user <PhysioNet Username> --ask-password \
     -P data/mimic \
     https://physionet.org/files/mimiciv/3.1/
```


### 3. Download The MIMIC-IV-Note Dataset

This will be used populate the `note` table

```
wget -r -N -c -np --user <PhysioNet Username> --ask-password \
     -P data/mimic \
     https://physionet.org/files/mimic-iv-note/2.2/
```

### (Optional) Populating note_nlp

This will be used to populate the `note_nlp` table.

The note_nlp table consists of 200m annotations. This can be computationally expensive. Precomputed alternatives are available below.

```
wget -P data/mimic/annotations \
     -O data/mimic/annotations/discharge_annotations.csv.gz \
     https://cogstack-mimic-demo.sites.er.kcl.ac.uk/annotations/discharge_annotations.csv.gz
```

```
wget -P data/mimic/annotations \
     -O data/mimic/annotations/radiology_annotations.csv.gz \
     https://cogstack-mimic-demo.sites.er.kcl.ac.uk/annotations/radiology_annotations.csv.gz
```

Or download the pre-built note_nlp table directly:

In `csv.gz` format:

```
wget -P data \
     -O data/note_nlp.csv.gz \
     https://cogstack-mimic-demo.sites.er.kcl.ac.uk/annotations/note_nlp.csv.gz
```

In `parquet` format:

```
wget -P data \
     -O data/note_nlp.parquet \
     https://cogstack-mimic-demo.sites.er.kcl.ac.uk/annotations/note_nlp.parquet
```

Add either of these sources to the schema.

### 4. (Optional) Download MIMIC-CXR Metadata

This step is required only if you want to include chest X-ray imaging data via the MI-CDM imaging extension.

#### Prerequisites

1. Complete **CITI Data or Specimens Only Research** training
2. Create/login to PhysioNet account
3. Request access to MIMIC-CXR-JPG: https://physionet.org/content/mimic-cxr-jpg/2.1.0/
4. Sign the Data Use Agreement

#### Download via Google Cloud Storage (Recommended)

```bash
# Authenticate with your linked Google account
gcloud auth login

# Set your billing project (required for requester-pays bucket)
gcloud config set project YOUR_PROJECT_ID

# Download metadata files only (~75 MB total)
gsutil -u YOUR_PROJECT_ID cp \
    gs://mimic-cxr-jpg-2.1.0.physionet.org/mimic-cxr-2.0.0-metadata.csv.gz \
    gs://mimic-cxr-jpg-2.1.0.physionet.org/mimic-cxr-2.0.0-chexpert.csv.gz \
    gs://mimic-cxr-jpg-2.1.0.physionet.org/mimic-cxr-2.0.0-split.csv.gz \
    data/mimic_cxr/
```

#### Alternative: Download via wget

```bash
wget --user <PhysioNet Username> --ask-password \
    -P data/mimic_cxr \
    https://physionet.org/files/mimic-cxr-jpg/2.1.0/mimic-cxr-2.0.0-metadata.csv.gz \
    https://physionet.org/files/mimic-cxr-jpg/2.1.0/mimic-cxr-2.0.0-chexpert.csv.gz \
    https://physionet.org/files/mimic-cxr-jpg/2.1.0/mimic-cxr-2.0.0-split.csv.gz
```

The three files to download are:

| File | Description |
|------|-------------|
| `mimic-cxr-2.0.0-metadata.csv.gz` | DICOM metadata (ViewPosition, StudyDate, image dimensions) |
| `mimic-cxr-2.0.0-chexpert.csv.gz` | CheXpert NLP-derived labels (14 radiological findings) |
| `mimic-cxr-2.0.0-split.csv.gz` | Train/validate/test splits with DICOM ID mapping |

> **Note:** The actual JPEG images (~558 GB) are not required for the ETL pipeline. Image paths and GCS URIs are stored in the `image_occurrence` table for on-demand access.

### 5. Create Initial Databases

Create the custom vocabularies database:

```
python load_vocabularies_to_duckdb.py
```

Create the MIMIC-IV database:

```
python load_mimic_to_duckdb.py
```

If using MIMIC-CXR, load the imaging metadata:

```
python load_mimic_cxr_to_duckdb.py
```

### 6. Run DBT

To run the entire pipeline:

```
dbt run
```

To generate specific tables only, for example person:

```
dbt run -s +person
```

To run only the MIMIC-CXR imaging models:

```
dbt run --select tag:mimic_cxr
```

### 7. Export the OMOP CDM

Copy every table in the `omop_gold` schema (clinical and vocabulary tables) into a standalone DuckDB file, under the schema `omopv5`:

```
python export_omop_gold.py mimic_iv.duckdb
```

The script will not overwrite an existing file.

---

## Data Model Overview

### OMOP CDM Tables

The pipeline produces the standard OMOP CDM clinical tables: `person`, `visit_occurrence`, `visit_detail`, `condition_occurrence`, `procedure_occurrence`, `drug_exposure`, `measurement`, `observation`, `note`, `note_nlp`, and supporting tables, plus the standardized vocabulary tables (`concept`, `concept_relationship`, `concept_ancestor`, `concept_synonym`, `concept_class`, `domain`, `relationship`, `vocabulary`, `drug_strength`, `source_to_concept_map`).

Identifiers are 32-bit integers, as in the OMOP CDM DDL. `person_id` is the MIMIC `subject_id`. Other ids are numbered in a fixed order, so rerunning the pipeline on the same data gives the same ids. `note_nlp_id` is still a 64-bit hash.

### MI-CDM Imaging Extension

When MIMIC-CXR data is loaded, two additional gold-layer tables are produced:

| Table | Description |
|-------|-------------|
| `image_occurrence` | One row per chest X-ray DICOM image. Includes person/visit linkage, study date, image dimensions, view position, and file paths (local and GCS). |
| `image_feature` | One row per CheXpert finding per image. Each of the 14 radiological findings is mapped to a standard SNOMED concept via `data/custom_mappings/gcpt_chexpert_findings.csv`. Feature values: `1.0` (positive), `-1.0` (negative/absent), `0.0` (uncertain). |

CXR studies are linked to OMOP `visit_occurrence` records by matching `subject_id` and verifying that the study date falls within the visit window.

### Metrics Models

Three summary tables are available in `models/gold/metrics/`:

| Table | Description |
|-------|-------------|
| `me_total` | Record counts for every OMOP CDM table |
| `me_mapping_rate` | Concept mapping coverage rates (count, percent, total) for each `concept_id` field across all tables |
| `me_persons_visits` | Demographic breakdowns (race, ethnicity, gender), visit statistics by type, observation period averages, and death counts |

Run metrics models with:

```
dbt run --select me_total me_mapping_rate me_persons_visits
```
