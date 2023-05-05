# terraform-aws-rke2
Terraform module to buld a simple RKE2 cluster.

## History
### v0.1.0
The first release.

### v0.2
Add
- Server Taints Option
- Server Disable Option
- Token Auto Creation
- Allocate Public IP fix when server.single is true
- Documents

## v0.3
- Auto delete terminated agent node from cluster.
- Restore automation.

## v0.4
- Better restore automation.
### v0.4.1
- Fixed to reboot agents.
### v0.4.2
- Refactor initial process.
- Add suport EBS-CSI Driver. Use addon.aws_ebs_csi_driver = "latest".
### v0.4.3
- Add IAM Policy automatically when EBS-CSI Driver is specified.
### (v0.4.4)
- Add monitoring attribute and set turned off by default.
### v0.4.5
- Add auto restore.
### v0.4.6
- Fix issue: agent script.

## v0.5
### v0.5.0
- Control-Plane: Now managed by not EC2 Fleet but ASG.
### v0.5.1
- Fix S3 spec change for default public access blocking.


