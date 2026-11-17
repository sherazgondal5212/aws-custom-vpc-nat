# Test: private instance egress through the NAT Gateway

Create an SSM role and instance profile (AmazonSSMManagedInstanceCore), a security group with no inbound rules,
and a t3.micro (Amazon Linux 2023) in a private subnet with no public IP.

Open EC2 > Instance > Connect > Session Manager, then run inside the instance:

    hostname
    curl -s https://checkip.amazonaws.com    # must equal the NAT Gateway Elastic IP
    curl -sI https://aws.amazon.com | head -1

Result: hostname ip-10-0-11-130.ec2.internal, IP 100.61.160.187 (NAT EIP), HTTP/2 200.
