# AWS Custom VPC with Public/Private Subnets and NAT Gateway

A two-AZ VPC built with the AWS CLI. A private instance reaches the internet outbound through a NAT Gateway, with no public IP and no inbound rules.

By [Gondal Digital Agency](https://gondaldigitalagency.com).

## Architecture

- VPC `10.0.0.0/16`, DNS hostnames enabled
- 2 public subnets (`10.0.1.0/24`, `10.0.2.0/24`) routed to the Internet Gateway
- 2 private subnets (`10.0.11.0/24`, `10.0.12.0/24`) routed to the NAT Gateway
- 1 NAT Gateway with an Elastic IP in a public subnet
- Test instance: t3.micro, Amazon Linux 2023, private subnet, no public IP, access via SSM Session Manager

## Design decisions

| Decision | Reason |
|---|---|
| NAT Gateway in a public subnet | It needs a route to the Internet Gateway |
| Single NAT Gateway | Keeps lab cost low. Production should use one NAT per AZ |
| SSM instead of SSH | No key pair, no open port 22, no public IP |
| Separate route tables | Private subnets stay unreachable from the internet |

## Verification

Run inside the private instance through Session Manager:

    $ hostname
    ip-10-0-11-130.ec2.internal
    $ curl -s https://checkip.amazonaws.com
    100.61.160.187
    $ curl -sI https://aws.amazon.com | head -1
    HTTP/2 200

The egress IP matches the NAT Gateway Elastic IP. The instance had no public IPv4 address and registered as Online in SSM.

Screenshots (SSM test, resource map, both route tables, NAT Gateway): [docs/project-2-1-evidence.pdf](docs/project-2-1-evidence.pdf)

## Reproduce

The files in `commands/` are the commands as executed in CloudShell during the lab: `build.sh`, `test.md`, `cleanup.sh`.

## Cost note

A NAT Gateway is billed hourly plus per GB processed. This lab was run in one sitting, then all resources were deleted and verified.

## Lessons learned

- A `curl` in CloudShell returns CloudShell's own IP. The egress test must run on the private instance.
- Delete in dependency order: instance, NAT, Elastic IP, route tables, IGW, subnets, VPC.

## Possible improvements

NAT per AZ, VPC Flow Logs, an S3 VPC endpoint, and a Terraform version.
