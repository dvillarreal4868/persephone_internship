#!/usr/bin/env nextflow

/*
 * Parameters
 */
params.s3_bucket = "dvillarreal/results"
params.s3_prefix = "${new Date().format('yyyyMMdd_HHmmss')}/"

/*
 * Upload files to S3
 */
process upload_to_s3 {
    tag "Uploading ${sample_id}"

    input:
    tuple val(sample_id), path(files)

    script:
    """
    for file in ${files}; do
        aws s3 cp "\$file" s3://${params.s3_bucket}/${params.s3_prefix}
    done
    """
}

/*
 * Alternative upload process that takes a directory path
 */
process upload_dir_to_s3 {
    tag "Uploading directory to S3"

    input:
    path input_files

    script:
    """
    for file in ${input_files}; do
        aws s3 cp "\$file" s3://${params.s3_bucket}/${params.s3_prefix}
    done
    """
}

/*
 * Workflow for standalone execution
 */
workflow {
    // This is only executed when this script is run directly
    // Create a channel from the input directory
    Channel
        .fromPath("${params.input_dir}/*")
        .ifEmpty { error "No files found in ${params.input_dir}" }
        .set { input_files }

    // Run upload_dir_to_s3
    upload_dir_to_s3(input_files)
}

