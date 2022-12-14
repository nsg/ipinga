# Ipinga

Ipinga is a minimal bash based script that does passive Icinga2 checks via the Icinga API. It assumes that services are already configured, dynamic service creation is out of scope for this tool.

## Use case

I have an Icinga2 server and I like to make remote checks that needs to be executed on the remote host. I feel that installing, configuring and running an Icinga client and all Nagios plugins are to heavy, especially in small containers.

## Project status

Experimental

## Installation

Run `./install.sh` as root to deploy it to `/opt/ipinga`. Systemd services called  `ipinga-root.service` and `ipinga-user.service` will also be installed.

Open `/etc/ipinga.conf` and provide the URI and credentials to the Icinga API. You also need to configure Icinga (examples below).

That should do it! Finally Enable and start the services

```
systemctl enable --now ipinga-root.service
systemctl enable --now ipinga-user.service
```

## Icinga Configuration Examples

### The API user

```sh
object ApiUser "my-username" {
  password = "my-password"

  permissions = [ "actions/process-check-result" ]
}
```

### A dummy host with no checks

```sh
template Host "dummy-host" {
  max_check_attempts = 3
  check_interval = 1m
  retry_interval = 30s

  vars.dummy_state = 0
  vars.dummy_text = "No host check"
  vars.passive_host = true

  check_command = "dummy"
}

object Host "my-host-1" {
  import "dummy-host"
}
```

### Add services to the above host

```sh
template Service "passive-service" {
  import "generic-service"

  enable_active_checks = false
  check_command = "dummy"
  vars.dummy_text = "No Passive Check Result Received"
  vars.dummy_state = "3"
}

apply Service "Passive Disk Usage" {
  import "passive-service"
  assign where host.vars.passive_host
}
```

You need to match the service name with the `CHECK_NAME` variable in the check scripts.
