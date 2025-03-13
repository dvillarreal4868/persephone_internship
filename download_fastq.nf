#!/usr/bin/env nextflow

/*
 * Download FASTQ files from S3 bucket based on sample IDs extracted from a TSV file
 */

/*
 * Parameters
 */
params.input_file = "dvillarreal/data/metadata/wgs98_sample_manifest_sub.tsv"
params.column_name = "sample_id"
params.s3_bucket = null // User will provide this
params.s3_directory = null // User will provide this
params.output_dir = "downloaded_fastq"      // Local output directory
params.file_suffix = "_{R}.fastq.gz"        // Pattern for R1/R2 files
params.help = false

// Print help message
if (params.help) {
    log.info"""
    ===============================================
    FASTQ Download from S3 - NF Pipeline
    ===============================================
    
    Usage:
    
    nextflow run download_fastq.nf --input_file [TSV_FILE] --column_name [COLUMN] --s3_bucket [S3_BUCKET] --s3_directory [S3_DIR_PATH] --output_dir [OUTPUT_DIR] --file_suffix [SUFFIX_PATTERN]
    
    Parameters:
    --input_file    TSV file containing sample IDs (default: ${params.input_file})
    --column_name   Column name in TSV file containing sample IDs (default: ${params.column_name})
    --s3_bucket     S3 bucket name with s3:// prefix (default: ${params.s3_bucket})
    --s3_directory  Directory within the S3 bucket containing FASTQ files (default: ${params.s3_directory})
    --output_dir    Local directory to save downloaded files (default: ${params.output_dir})
    --file_suffix   File suffix pattern, use {R} as a placeholder for R1/R2 (default: ${params.file_suffix})
    --help          Print this help message
    
    Example:
    nextflow run download_fastq.nf --s3_bucket s3://my-bucket --s3_directory raw/sequencing/data
    """
    exit 0
}

// Log parameters to console
log.info"""
Starting S3 FASTQ download with parameters:
-------------------------------------------
Input file:       ${params.input_file}
Column name:      ${params.column_name}
S3 bucket:        ${params.s3_bucket}
S3 directory:     ${params.s3_directory}
Output directory: ${params.output_dir}
File suffix:      ${params.file_suffix}
"""

/*
 * Create a channel from input and make it available
 */
def getSampleIds() {
    return Channel
        .fromPath("${params.input_file}")
        .splitCsv(sep: '\t', header: true)
        .map { row -> row[params.column_name] }
}

/*
 * Process to download files from S3
 */
process downloadFromS3 {
    publishDir "${params.output_dir}", mode: 'copy'
    
    input:
    tuple val(sample_id), val(file_patterns)
    
    output:
    tuple val(sample_id), path("*fastq.gz"), emit: fastq_files
    
    script:
    r1_filename = "${sample_id}${params.file_suffix.replace('{R}', 'R1')}"
    r2_filename = "${sample_id}${params.file_suffix.replace('{R}', 'R2')}"
    r1_s3path = "${params.s3_bucket}/${params.s3_directory}/${r1_filename}"
    r2_s3path = "${params.s3_bucket}/${params.s3_directory}/${r2_filename}"
    
    """
    aws s3 cp ${r1_s3path} ./ --no-progress
    aws s3 cp ${r2_s3path} ./ --no-progress
    
    echo "[INFO] Downloaded ${r1_filename} and ${r2_filename} for sample ${sample_id}"
    """
}

/*
 * Demonstrate usage when run directly
 */
workflow {
    // Only execute this when run directly (not when imported)
    if (workflow.scriptName == workflow.commandLine.split(' ')[1]) {
        // Get sample IDs and create file patterns
        fastq_pairs = getSampleIds()
            .map { sample_id -> 
                def r1_pattern = "${sample_id}${params.file_suffix.replace('{R}', 'R1')}"
                def r2_pattern = "${sample_id}${params.file_suffix.replace('{R}', 'R2')}"
                return tuple(sample_id, [r1_pattern, r2_pattern])
            }
        
        // Show samples to be processed
        fastq_pairs.view { sample_id, patterns -> "Will download for sample: $sample_id (${patterns[0]}, ${patterns[1]})" }
        
        // Download files from S3
        downloadFromS3(fastq_pairs)
        
        // Show downloaded files
        downloadFromS3.out.fastq_files.view { sample_id, files -> "Downloaded files for $sample_id: $files" }
    }
}

// Remove the export block completely - just delete these lines
// export {
//     getSampleIds
//     downloadFromS3
// }

