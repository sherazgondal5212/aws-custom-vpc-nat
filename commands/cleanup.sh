#!/bin/bash
# Delete in dependency order. Requires ~/vpc-lab-ids.env from the build
source ~/vpc-lab-ids.env
aws ec2 terminate-instances --instance-ids $INST && aws ec2 wait instance-terminated --instance-ids $INST
aws ec2 delete-security-group --group-id $SG
aws iam remove-role-from-instance-profile --instance-profile-name gda-vpc-lab-ssm --role-name gda-vpc-lab-ssm
aws iam delete-instance-profile --instance-profile-name gda-vpc-lab-ssm
aws iam detach-role-policy --role-name gda-vpc-lab-ssm --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
aws iam delete-role --role-name gda-vpc-lab-ssm
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_ID && aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_ID
aws ec2 release-address --allocation-id $EIP_ALLOC
for rt in $PUB_RT $PRV_RT; do
  for a in $(aws ec2 describe-route-tables --route-table-ids $rt --query 'RouteTables[0].Associations[?Main==`false`].RouteTableAssociationId' --output text); do
    aws ec2 disassociate-route-table --association-id $a; done
  aws ec2 delete-route-table --route-table-id $rt
done
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
for s in $PUB1 $PUB2 $PRV1 $PRV2; do aws ec2 delete-subnet --subnet-id $s; done
aws ec2 delete-vpc --vpc-id $VPC_ID
