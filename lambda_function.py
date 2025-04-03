# Imports
import boto3
import urllib.parse

# Function
def lambda_handler(event, context):

    # Extract bucket and key from the S3 event
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'])

    # Print
    print(f"Bucket: {bucket}; Key: {key}")
    
    # Only proceed for .tsv files in the dvillarreal/metadata/ prefix
    if key.startswith("metadata/") and key.endswith(".tsv"):

        # Filename
        filename = key.split("/")[-1] # e.g., "datafile.tsv"

        # Define outpput
        output_name = filename.replace(".tsv", "_modified.tsv")
        output_name_log = f"log_{filename.replace('.tsv', '.txt')}"
        
        # Define the EC2 launch parameters
        ami_id = "ami-0336070cc73c86f70" # Prebuilt AMI ID
        instance_type = "t2.micro" # instance size
        profile_name = "EC2ProcessingRole" # EC2 IAM role name (instance profile)
        
        # User data script to process the file on the EC2 instance

        ## Shebang
        user_data_script = "#!/bin/bash\n"

        ## Generate a log
        user_data_script += f"echo 'Hello, I made a file.' > /tmp/{output_name_log}\n"
        user_data_script += f"aws s3 cp /tmp/{output_name_log}"
        user_data_script += f" s3://{bucket}/processed_data/{output_name_log}\n"

        ## Actual command

        ### Copy the file that triggered into the instance
        user_data_script += f"aws s3 cp s3://{bucket}/{key} /tmp/{filename}\n"

        ### Modified the file by appending a suffix
        user_data_script += f"cp /tmp/{filename} /tmp/{output_name}\n"

        ### Upload modified file into s3 bucket
        user_data_script += f"aws s3 cp /tmp/{output_name}"
        user_data_script += f" s3://{bucket}/processed_data/{output_name}\n"

        ## Terminate the instance
        user_data_script += f"INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)\n"
        user_data_script += f"aws ec2 terminate-instances --instance-ids $INSTANCE_ID --region us-west-2"

        # Launch the EC2 instance
        ec2 = boto3.client('ec2')

        # Try
        try:

            response = ec2.run_instances(
                ImageId = ami_id,
                InstanceType = instance_type,
                IamInstanceProfile = {'Name' : profile_name},
                MinCount = 1,
                MaxCount = 1,
                UserData = user_data_script
            )

            # Print
            print(f"EC2 launched: {response}")

        except Exception as e:

            # Print
            print(f"Error launching EC2: {e}")

    # Print
    print('Done')
