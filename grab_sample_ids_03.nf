#!/usr/bin/env nextflow

/*
 * Extract specific column from a tsv file and create a channel of sample IDs
 */

/*
 * Parameters
 */
params.input_file = "dvillarreal/data/metadata/wgs98_sample_manifest_sub.tsv"
params.column_name = "sample_id"

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
 * Generate file pairs based on sample IDs 
 */
def getReadPairsFromSampleIds(basedir, filesuffix) {
    return getSampleIds()
        .map { sample_id -> 
            def r1 = file("${basedir}/${sample_id}${filesuffix.replace('{R}', 'R1')}")
            def r2 = file("${basedir}/${sample_id}${filesuffix.replace('{R}', 'R2')}")
            return tuple(sample_id, [r1, r2])
        }
}

// Export the functions
workflow {
    // Example usage when run directly
    getSampleIds().view()
}
