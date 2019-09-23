import boto3
region = 'ca-central-1'
instances = ['i-098823b3cf8221fd4', 'i-0ebcb52f7107a2af1']
ec2 = boto3.client('ec2', region_name=region)

def lambda_handler(event, context):
    ec2.stop_instances(InstanceIds=instances)
    print('stopped your instances: ' + str(instances))
