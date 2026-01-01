a.Create 2 Ec2 instances.
b.Create Lambda function with python code to detect AWS EC2 data detection with attached permissions.
c.Set Up AWS Config(Custom Config Rule,Config rule ARN as Lambda,Resource types as EC2 Instance, trigger type as Configuration changes )
d.Enable Detailed Monitoring on one instance and Disable on another from EC2>monitoring>Manage Detailed Monitoring section.
e.Check status of compliant or noncompliant in AWS config>Rules>Newly set dashboard 