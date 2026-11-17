#!/bin/bash
# Project 2.1: custom VPC, public/private subnets, IGW, NAT Gateway
export AWS_REGION=us-east-1 AWS_DEFAULT_REGION=us-east-1
P=gda-vpc-lab
tag() { echo "ResourceType=$1,Tags=[{Key=Name,Value=$P-$2},{Key=Project,Value=$P}]"; }
AZ1=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[0].ZoneName' --output text)
AZ2=$(aws ec2 describe-availability-zones --query 'AvailabilityZones[1].ZoneName' --output text)
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --tag-specifications "$(tag vpc vpc)" --query Vpc.VpcId --output text)
aws ec2 modify-vpc-attribute --vpc-id $VPC_ID --enable-dns-hostnames
mk_subnet() { aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $1 --availability-zone $2 --tag-specifications "$(tag subnet $3)" --query Subnet.SubnetId --output text; }
PUB1=$(mk_subnet 10.0.1.0/24 $AZ1 public-1)
PUB2=$(mk_subnet 10.0.2.0/24 $AZ2 public-2)
PRV1=$(mk_subnet 10.0.11.0/24 $AZ1 private-1)
PRV2=$(mk_subnet 10.0.12.0/24 $AZ2 private-2)
for s in $PUB1 $PUB2; do aws ec2 modify-subnet-attribute --subnet-id $s --map-public-ip-on-launch; done
cat > ~/vpc-lab-ids.env <<EOT
export AWS_REGION=$AWS_REGION AWS_DEFAULT_REGION=$AWS_REGION
export VPC_ID=$VPC_ID PUB1=$PUB1 PUB2=$PUB2 PRV1=$PRV1 PRV2=$PRV2
EOT
IGW_ID=$(aws ec2 create-internet-gateway --tag-specifications "$(tag internet-gateway igw)" --query InternetGateway.InternetGatewayId --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
PUB_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications "$(tag route-table public-rt)" --query RouteTable.RouteTableId --output text)
aws ec2 create-route --route-table-id $PUB_RT --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
for s in $PUB1 $PUB2; do aws ec2 associate-route-table --route-table-id $PUB_RT --subnet-id $s; done
EIP_ALLOC=$(aws ec2 allocate-address --domain vpc --tag-specifications "$(tag elastic-ip nat-eip)" --query AllocationId --output text)
NAT_ID=$(aws ec2 create-nat-gateway --subnet-id $PUB1 --allocation-id $EIP_ALLOC --tag-specifications "$(tag natgateway nat)" --query NatGateway.NatGatewayId --output text)
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_ID
PRV_RT=$(aws ec2 create-route-table --vpc-id $VPC_ID --tag-specifications "$(tag route-table private-rt)" --query RouteTable.RouteTableId --output text)
aws ec2 create-route --route-table-id $PRV_RT --destination-cidr-block 0.0.0.0/0 --nat-gateway-id $NAT_ID
for s in $PRV1 $PRV2; do aws ec2 associate-route-table --route-table-id $PRV_RT --subnet-id $s; done
echo "export IGW_ID=$IGW_ID PUB_RT=$PUB_RT PRV_RT=$PRV_RT NAT_ID=$NAT_ID EIP_ALLOC=$EIP_ALLOC" >> ~/vpc-lab-ids.env
