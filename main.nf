#!/usr/bin/env nextflow

/*
 * Import external Nextflow scripts
 */
include { getSampleIds; downloadFromS3 } from '/home/ubuntu/dvillarreal/code/nextflow_scripts/download_fastq.nf'
include { run_trim_galore } from '/home/ubuntu/dvillarreal/code/nextflow_scripts/trim_seqs.nf'
include { upload_to_s3 } from '/home/ubuntu/dvillarreal/code/nextflow_scripts/upload_files.nf'
include { getReadPairsFromSampleIds } from '/home/ubuntu/dvillarreal/code/nextflow_scripts/grab_sample_ids.nf'

/*
 * Parameters
 */
// Parameters for file handling
params.input_file = "dvillarreal/data/metadata/wgs98_sample_manifest_sub.tsv"
params.column_name = "sample_id"
params.s3_bucket = null // S3 bucket for downloading and uploading
params.s3_directory = null // S3 directory for downloading
params.output_dir = "downloaded_fastq" // Directory to store downloaded files
params.file_suffix = "_{R}.fastq.gz" // Pattern for R1/R2 files

// Output parameters for processing pipeline
params.trimdir = "dvillarreal/results/illumna_run/wgs98/trimmed_2/"
params.s3_prefix = "${new Date().format('yyyyMMdd_HHmmss')}/"

/*
 * Workflow
 */
workflow {
    // Option 1: Download files from S3 first
    if (params.s3_bucket && params.s3_directory) {
        // Get sample IDs and create file patterns
        fastq_pairs = getSampleIds()
            .map { sample_id -> 
                def r1_pattern = "${sample_id}${params.file_suffix.replace('{R}', 'R1')}"
                def r2_pattern = "${sample_id}${params.file_suffix.replace('{R}', 'R2')}"
                return tuple(sample_id, [r1_pattern, r2_pattern])
            }
            
        // Download files from S3
        downloaded_files_ch = downloadFromS3(fastq_pairs)
        
        // Use downloaded files for trimming
        trimmed_files_ch = run_trim_galore(downloaded_files_ch.fastq_files)
    }
    // Option 2: Use local files if no S3 bucket/directory is specified
    else {
        // Generate read pairs channel from sample IDs and local directory
        read_pairs_ch = getReadPairsFromSampleIds(params.basedir, params.filesuffix)
        
        // Run trimming
        trimmed_files_ch = run_trim_galore(read_pairs_ch)
    }

    // Upload trimmed files to S3
    upload_to_s3(trimmed_files_ch)
}
