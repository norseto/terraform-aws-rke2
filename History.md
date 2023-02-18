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
