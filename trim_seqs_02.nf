#!/usr/bin/env nextflow

/*
 * Parameters
 */
params.reads = "dvillarreal/data/illumna_run/wgs98/raw/*{R1,R2}.fastq.gz"
params.trimdir = "dvillarreal/results/illumna_run/wgs98/trimmed_2/"

/*
 * Run trim_galore
 */
process run_trim_galore {

    publishDir params.trimdir, mode: 'copy', overwrite: false

    input:
	tuple val(sample_id), path(reads)

    output:
	tuple val(sample_id), path("*")

    script:
	"""
	trim_galore --illumina --paired -q 20 --phred33 \
	--stringency 1 -e 0.1 --length 20 -o . ${reads}
	"""

}

workflow {

    // Make input channel
    Channel
	.fromFilePairs(params.reads, checkIfExists: true)
	.set { read_pairs_ch }	

    // Run trim_galore
    trim_ch = run_trim_galore(read_pairs_ch)

}

