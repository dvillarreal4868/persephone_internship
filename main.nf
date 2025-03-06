#!/usr/bin/env nextflow

/*
 * Import external Nextflow scripts
 */
include { run_trim_galore } from '/home/ubuntu/dvillarreal/code/nextflow_scripts/trim_seqs.nf'
include { upload_to_s3 } from '/home/ubuntu/dvillarreal/code/nextflow_scripts/upload_files.nf'
include { getReadPairsFromSampleIds } from '/home/ubuntu/dvillarreal/code/nextflow_scripts/grab_sample_ids.nf'

/*
 * Parameters
 */
// New parameters for file handling
params.input_file = "dvillarreal/data/metadata/wgs98_sample_manifest_sub.tsv"
params.column_name = "sample_id"
params.basedir = "dvillarreal/data/illumna_run/wgs98/raw"
params.filesuffix = "_{R}.fastq.gz"  // {R} will be replaced with R1 or R2

// Output parameters
params.trimdir = "dvillarreal/results/illumna_run/wgs98/trimmed_2/"
params.s3_bucket = "dvillarreal/results"
params.s3_prefix = "${new Date().format('yyyyMMdd_HHmmss')}/"

/*
 * Workflow
 */
workflow {
    // Generate read pairs channel from sample IDs
    read_pairs_ch = getReadPairsFromSampleIds(params.basedir, params.filesuffix)

    // Run trimming
    trimmed_files_ch = run_trim_galore(read_pairs_ch)

    // Upload files to S3 after trimming is complete
    upload_to_s3(trimmed_files_ch)
}
