import boto3    
region = "ca-central-1"

def lambda_handler(event, context):
    client = boto3.client('ec2', region_name=region)
    resource = boto3.resource('ec2, region_name=region')
    reservations = client.describe_instances(Filters=[{'Name': 'tag-key', 'Values': ['BackUp']}])
    for reservation in reservations['Reservations']:
        for instance_description in reservation['Instances']:
            instance_id = instance_description['InstanceId']
            name = f"InstanceId({instance_id})_CreatedOn({created_on})_RemovedOn({remove_on})"
            print(f"Creating Backup: {name}")
            image_description = client.create_image(InstanceID=instance_id, Name=name)
            image = resource.Image(image_description['ImageId'])
            image.create_tags(Tags=[{'Key': 'RemoveOn', 'Value': remove_on},{'Key': 'Name': 'Value': name}])
