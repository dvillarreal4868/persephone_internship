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
    // Extract the base bucket name without s3:// prefix
    def bucket_parts = params.s3_bucket.toString().replaceAll('^s3://', '').split('/', 2)
    def base_bucket = bucket_parts[0]
    
    // Build the complete path including any specified subdirectory
    def upload_path
    if (bucket_parts.length > 1) {
        upload_path = "${bucket_parts[1]}/${params.s3_prefix}"
    } else {
        upload_path = "results/${params.s3_prefix}"  // Default to 'results' subdirectory if not specified
    }
    
    """
    for file in ${files}; do
        aws s3 cp "\$file" s3://${base_bucket}/${upload_path}
        echo "Uploaded \$file to s3://${base_bucket}/${upload_path}"
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
    // Extract the base bucket name without s3:// prefix
    def bucket_parts = params.s3_bucket.toString().replaceAll('^s3://', '').split('/', 2)
    def base_bucket = bucket_parts[0]
    
    // Build the complete path including any specified subdirectory
    def upload_path
    if (bucket_parts.length > 1) {
        upload_path = "${bucket_parts[1]}/${params.s3_prefix}"
    } else {
        upload_path = "results/${params.s3_prefix}"  // Default to 'results' subdirectory if not specified
    }
    
    """
    for file in ${input_files}; do
        aws s3 cp "\$file" s3://${base_bucket}/${upload_path}
        echo "Uploaded \$file to s3://${base_bucket}/${upload_path}"
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
