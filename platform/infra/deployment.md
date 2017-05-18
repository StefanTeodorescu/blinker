# Deployment documentation

## Preliminaries

This document is a record of how the Blinker platform was deployed to Microsoft
Azure for the purpose of running a trial CTF. It is provided only as an example,
not a definitive guide. Any other deployment will necessarily want to deviate
from it, at least in terms of the domain names used. (Word of advice: you might
want something shorter than `help-gsx-get-his-degree.com`.)

## Building the required packages

Build all of the framework and the platform, and the challenges that will be used.

* `mkdir -p builddir/llvm{,-build}`
* `/path/to/blinker/source/framework/package-blinker-framework.sh`
* `/path/to/blinker/source/platform/package-blinker-platform.sh`
* &nbsp;
  ```
  for ch in {static_,}{re_normalize,amazing_rop,hommage_a_irc,mysecuresite,refunge,simple_bof}; do
  /path/to/blinker/source/challenges/package-blinker-challenges.sh $ch
  done
  ```
* `cd llvm`
* `/path/to/blinker/source/framework/llvm/create-build-tree.sh`
* `cd ../llvm-build`
* `../llvm/release_build.sh` (this will take a while)
* `mv blinker-llvm*.deb ..`
* `cd ..`

## Overview

The 4 server roles are: database, web, ctf backend, and storage/monitoring. Each
has its own subnet. Additionally, there are two other subnets for challenges:
one for bootstrapping, one for running live.

All server are running Ubuntu Server 16.04.0 LTS.

### Planned network layout

```
prod-web  10.0.0.0/24
prod-db   10.0.1.0/24
prod-mgmt 10.0.2.0/24
prod-ctf  10.0.3.0/24

challenge-bootstrap 10.0.100.0/25
challenge-prod      10.0.100.128/25
```

#### Azure-specific details

Production subnets belong to vnet `prod-vnet`, challenge subnets to
`challenge-vnet`. IP layouts for these are as below.

```
prod-vnet      10.0.0.0/20
challenge-vnet 10.0.100.0/24
```

The two vnets are set up with a peering, enabling 'network access'
between them. These must be set up manually.

Each subnet has its own network security group, which is assigned to both the
subnet and the network interface of individual hosts in that subnet. Additional
rules above the default for each NSG are as follows.

```
NSG                  PRIORITY  I/O A/D        SOURCE        DESTINATION PROTOCOL

prod-web               500      I   A        prod-mgmt         *:22       TCP
prod-web               700      I   A        prod-mgmt         *:5666     TCP
prod-web               1000     I   A          INET            *:443      TCP
prod-web               1010     I   A          INET            *:80       TCP
prod-web               2000     I   D           *               *         TCP
prod-web               2010     I   D           *               *         UDP
prod-web               2100     I   A        prod-mgmt          *          *
prod-web               2200     I   D           *               *          *

prod-db                500      I   A        prod-mgmt         *:22       TCP
prod-db                700      I   A        prod-mgmt         *:5666     TCP
prod-db                1000     I   A        prod-mgmt         *:5432     TCP
prod-db                1010     I   A        prod-web          *:5432     TCP
prod-db                1020     I   A        prod-ctf          *:5432     TCP
prod-db                2000     I   D           *               *         TCP
prod-db                2010     I   D           *               *         UDP
prod-db                2100     I   A        prod-mgmt          *          *
prod-db                2200     I   D           *               *          *

prod-mgmt              500      I   A          INET            *:22       TCP
prod-mgmt              1000     I   A          INET            *:443      TCP
prod-mgmt              1005     I   A          INET            *:80       TCP
prod-mgmt              1010     I   A        prod-web          *:8080     TCP
prod-mgmt              1020     I   A        prod-ctf          *:8080     TCP
prod-mgmt              1030     I   A   challenge-bootstrap    *:8080     TCP
prod-mgmt              1035     I   A   challenge-bootstrap    *:8000     TCP
prod-mgmt              1040     I   A        prod-web          *:8000     TCP
prod-mgmt              1050     I   A        prod-ctf          *:8000     TCP
prod-mgmt              1060     I   A        prod-ctf          *:8081     TCP
prod-mgmt              2000     I   D           *               *          *

prod-ctf               500      I   A        prod-mgmt         *:22       TCP
prod-ctf               700      I   A        prod-mgmt         *:5666     TCP
prod-ctf               2000     I   D           *               *         TCP
prod-ctf               2010     I   D           *               *         UDP
prod-ctf               2100     I   A        prod-mgmt          *          *
prod-ctf               2200     I   D           *               *          *

challenge-bootstrap    500      I   A        prod-mgmt         *:22       TCP
challenge-prod         500      I   A        prod-mgmt         *:22       TCP
challenge-prod         1000     I   D          INET            *:22       TCP
challenge-prod         1010     I   A          INET             *          *
challenge-prod         1000     O   D           *               *          *
```

The file `azure-prod-net.json` contains an Azure Resource Manager template that
has the production network configured (without the peerings). Similarly
`azure-challenge-net.json` is for the challenge network.

## Role-agnostic configuration

1. Add the `beevm/nagios4` PPA.
   * `sudo add-apt-repository ppa:beevm/nagios4`
   * `sudo apt-get update`
2. `dpkg-statoverride --add root root 4755 /usr/lib/nagios4/lib/x86_64-linux-gnu/check_icmp`
3. Install the following packages: `dnsmasq supervisor nagios4-plugins nagios4-nrpe haveged`
4. Create `/etc/supervisor/conf.d/nrpe.conf`

   ```
   [program:nrpe]
   command = /usr/lib/nagios4-nrpe/bin/nagios4-nrpe -c /etc/nagios4/nrpe.cfg -f -n
   #user = nagios4-nrpe # drops privileges itself
   startsecs = 5
   ```
5. Edit `/etc/nagios4/nrpe.cfg`

   ```
   log_facility=daemon
   debug=0
   pid_file=/var/run/nrpe.pid
   server_port=5666
   nrpe_user=nagios4-nrpe
   nrpe_group=nagios4-nrpe
   allowed_hosts=10.0.2.0/24
   dont_blame_nrpe=0
   allow_bash_command_substitution=0
   command_timeout=60
   connection_timeout=300

   include_dir=/etc/nagios4/nrpe-commands
   ```
6. Copy the config file appropriate for this host from `nagios-nrpe` to `/etc/nagios4/nrpe-commands`
   * `chown -R root:root /etc/nagios4/nrpe-commands`
   * `chmod -R o-w /etc/nagios4/nrpe-commands`
7. `mkdir /usr/local/lib/nagios4-plugins`
8. Copy all files from `nagios-checks` to `/usr/local/lib/nagios4-plugins`
   * `chown -R root:root /usr/local/lib/nagios4-plugins`
   * `chmod -R o-w /usr/local/lib/nagios4-plugins`
9. Setup supervisord
   * `systemctl enable supervisor`
   * `systemctl start supervisor`

## The database server

Let us call it `prod-db`.

1. Install the following package: `postgresql`
2. Initialize the database schema
   * `sudo -u postgres psql -f schema.sql`
3. Configure postgres
   1. Add the following to `pg_hba.conf`

      ```
      host	anon	blinker_web	10.0.0.0/24	md5
      host	priv	blinker_web	10.0.0.0/24	md5
      host	anon	blinker_ctf	10.0.3.0/24	md5
      host	anon	blinker_monitoring	10.0.2.0/24	md5
      ```
   2. Make the following changes in `postgresql.conf`

      ```
      listen_addresses *
      ```
   3. Set blinker role passwords
      * `pwgen -s 20`
      * `sudo -u postgres psql`
      * `ALTER USER "blinker_" WITH PASSWORD '...';`
   4. Restart postgres
      * `systemctl restart postgresql`

## The storage/monitoring server

Let us call it `prod-mgmt`. The internal IP should be statically assigned.

### DNS
1. Add a CNAME record for `prod-mgmt.help-gsx-get-his-degree.com` pointing to the Azure-provided domain for the public IP belonging to prod-mgmt.

### Package repository
1. Install aptly
   * `wget -qO - https://www.aptly.info/pubkey.txt | sudo apt-key add -`
   * `echo 'deb http://repo.aptly.info/ squeeze main' > /etc/apt/sources.list.d/aptly.list`
   * `apt-get update`
   * `apt-get install aptly`
2. Create the user `aptly`
   * `useradd -m -r aptly`
3. Generate a package signing key as the user `aptly`
   * Generate:

     ```
     gpg --batch --gen-key <<EOF
     %echo Generating key
     Key-Type: RSA
     Key-Usage: sign
     Key-Length: 2048
     Name-Real: Blinker Package Signing
     Name-Comment: (prod)
     Name-Email: contact@help-gsx-get-his-degree.com
     Expire-Date: 0
     %commit
     %echo done
     EOF
     ```
   * Export: `gpg -a --export 'Blinker Package Signing' > /home/aptly/package-signing.pub`
4. Create the file `/home/aptly/.aptly.conf`

   ```
   {
   "rootDir": "/home/aptly",
   "downloadConcurrency": 4,
   "downloadSpeedLimit": 0,
   "architectures": ["amd64"],
   "dependencyFollowSuggests": false,
   "dependencyFollowRecommends": false,
   "dependencyFollowAllVariants": false,
   "dependencyFollowSource": false,
   "gpgDisableSign": false,
   "gpgDisableVerify": false,
   "downloadSourcePackages": false,
   "ppaDistributorID": "ubuntu",
   "ppaCodename": "",
   "skipContentsPublishing": false,
   "S3PublishEndpoints": {},
   "SwiftPublishEndpoints": {}
   }
   ```
5. Configure aptly (as the user `aptly` execute the commands below)
   * `aptly repo create -architectures=amd64 infra`
   * `aptly publish repo -architectures=amd64 -distribution=xenial infra infra`
   * `aptly repo create -architectures=amd64 challenges`
   * `aptly publish repo -architectures=amd64 -distribution=xenial challenges challenges`
6. Create the file `/etc/supervisor/conf.d/aptly.conf`

   ```
   [program:aptly-serve]
   command = aptly serve -listen="prod-mgmt:8080"
   directory = /home/aptly
   user = aptly
   startsecs = 5

   [program:aptly-api]
   command = aptly api serve -listen="prod-mgmt:8081"
   directory = /home/aptly
   user = aptly
   startsecs = 5
   ```
7. `supervisorctl update`
8. Upload all blinker packages into the `infra` repository
   * These were built at the very beginning of this guide.
   * `.tools/aptly-manage.rb <api-host> <api-port> infra <deb>`

### Handout filestore

1. `apt-key add /home/aptly/package-signing.pub`
2. Add the infra repo to the APT source list
   * `echo 'deb http://prod-mgmt:8080/infra xenial main' > /etc/apt/sources.list.d/prod-mgmt-infra.list`
3. `apt-get update`
4. Install the `blinker-filestore` package
5. Edit `/etc/blinker/filestore.yml`

   ```
   environment: production
   port: 8000
   upload_dir: /var/lib/blinker/handouts
   exceptions_dir: /var/lib/blinker/exceptions
   pubkey: /etc/blinker/package-signing.pub
   ```
6. `cp /home/aptly/package-signing.pub /etc/blinker`
7. `systemctl restart supervisor`

### Remote access to challenge VMs
1. Generate an SSH key pair as root
   * `ssh-keygen -t rsa -b 2048`
2. Locate the public key in `/root/.ssh/id_rsa.pub`, which will be needed for configuring blinker-ctf

### Email sending

1. Install the following package: `ssmtp`
2. Edit the config file `/etc/ssmtp/ssmtp.conf`

   ```
   root=admin@help-gsx-get-his-degree.com

   mailhub=smtp.sendgrid.net:587
   AuthUser=apikey
   AuthPass=### TO BE DONE ###
   UseSTARTTLS=YES

   hostname=prod-mgmt.help-gsx-get-his-degree.com
   ```
3. Insert an actual Sendgrid API key in the config

### Monitoring

1. Install the following packages: `nagios4 nginx fcgiwrap php-fpm php-gd letsencrypt postgresql-client`
2. Configure nginx
   1. Delete all symlinks from `/etc/nginx/sites-enabled`
   2. Copy the following vhost config files under `/etc/nginx/sites-available`, paying attention to set the owner/group to root:root and the mode to 640 on each
      * `nagios`
      * `redirect-http`, filling in the server name `prod-mgmt.help-gsx-get-his-degree.com`
   3. Symlink `/etc/nginx/sites-available/redirect-http` and
      `/etc/nginx/sites-available/nagios` under `/etc/nginx/sites-enabled`
   4. Set the following in `/etc/nginx/nginx.conf`

      ```
      server_tokens off;
      ```
   5. `systemctl restart nginx`
   6. Remove everything from under `/var/www`
3. Configure certbot
   1. `letsencrypt certonly --webroot -w /var/www/ -d prod-mgmt.help-gsx-get-his-degree.com`
   2. Test that running `letsencrypt renew --dry-run --agree-tos` works as intended
   3. Add the following to the root crontab:

      `42 7 * * * letsencrypt renew -n --agree-tos && /usr/sbin/service nginx reload`
   4. Download the Let's Encrypt X3 intermediate certificate under `/etc/ssl/certs`
      * `wget https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem`
4. Enable nagios
   1. Set a password for nagios
      * `touch /etc/nagios4/htpasswd.users`
      * `chmod 640 /etc/nagios4/htpasswd.users`
      * `chgrp www-data /etc/nagios4/htpasswd.users`
      * `echo "nagiosadmin:$(openssl passwd -apr1)" >> /etc/nagios4/htpasswd.users`
   2. Symlink `/etc/nginx/sites-available/nagios` under `/etc/nginx/sites-enabled`
   3. Set up permissions for the command pipe
      * `dpkg-statoverride --update --add nagios4 www-data 2755 /var/lib/nagios4/rw`
      * `rm -f /var/lib/nagios4/rw/nagios.cmd`
   4. `systemctl restart nginx`
5. Configure nagios
   1. Delete all files from `/etc/nagios4/objects`
   2. Copy the config files from `nagios-objects` to `/etc/nagios4/objects`
      * `chown -R root:root /etc/nagios4/objects`
      * `chmod -R o-w /etc/nagios4/objects`
   3. Delete all `cfg_file` and `cfg_dir` directives from `/etc/nagios4/nagios.cfg`
   4. Add the following to `/etc/nagios4/nagios.cfg`

      ```
      date_format=iso8601
      admin_email=admin@help-gsx-get-his-degree.com
      admin_pager=admin@help-gsx-get-his-degree.com
      cfg_dir=/etc/nagios4/objects
      ```
   5. Set permissions on `/etc/nagios4/resource.cfg`
      * `chown root:nagios4 /etc/nagios4/resource.cfg`
      * `chmod 640 /etc/nagios4/resource.cfg`
   6. Edit `/etc/nagios4/resource.cfg`

      ```
      $USER1$=/usr/lib/nagios4/lib/x86_64-linux-gnu
      $USER2$=/usr/local/lib/nagios4-plugins
      $USER3$=### FILL IN THE PASSWORD FOR blinker_monitoring ###
      ```
   9. `systemctl enable nagios4`
   10. `systemctl start nagios4`

## The web server

Let us call it `prod-web-1`.

### DNS
1. Add an A record for `help-gsx-get-his-degree.com` pointing to the IP of `prod-web-1`.
   Note: in Azure, the public IP associated with `prod-web-1` should be statically assigned.
2. Add a CNAME record for `www.help-gsx-get-his-degree.com` pointing to `help-gsx-get-his-degree.com`.

### Nginx
1. Install the following package: `nginx`
2. Configure nginx
   1. `mkdir /var/cache/nginx`
   2. Delete all symlinks from `/etc/nginx/sites-enabled`
   3. Copy the following vhost config files under `/etc/nginx/sites-available`, paying attention to set the owner/group to root:root and the mode to 640 on each
      * `blinker`
      * `redirect-http`, filling in the server names `help-gsx-get-his-degree.com www.help-gsx-get-his-degree.com`
   4. Symlink `/etc/nginx/sites-available/redirect-http` and
      `/etc/nginx/sites-available/blinker` under `/etc/nginx/sites-enabled`
   5. Set the following in `/etc/nginx/nginx.conf`

      ```
      server_tokens off;
      ```
   6. `systemctl restart nginx`
   7. Remove everything from under `/var/www`

### Certbot
1. Install the following package: `letsencrypt`
2. `letsencrypt certonly --webroot -w /var/www/ -d help-gsx-get-his-degree.com -d www.help-gsx-get-his-degree.com`
3. Test that running `letsencrypt renew --dry-run --agree-tos` works as intended
4. Add the following to the root crontab:

   `42 7 * * * letsencrypt renew -n --agree-tos && /usr/sbin/service nginx reload`
5. Symlink `/etc/nginx/sites-available/blinker` under `/etc/nginx/sites-enabled`
6. Download the Let's Encrypt X3 intermediate certificate under `/etc/ssl/certs`
   * `wget https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem`
7. `systemctl restart nginx`

### Email sending

1. Install the following package: `ssmtp`
2. Edit the config file `/etc/ssmtp/ssmtp.conf`

   ```
   root=admin@help-gsx-get-his-degree.com

   mailhub=smtp.sendgrid.net:587
   AuthUser=apikey
   AuthPass=### TO BE DONE ###
   UseSTARTTLS=YES

   hostname=prod-web-1.help-gsx-get-his-degree.com
   ```
3. Insert an actual Sendgrid API key in the config
4. Make a copy of `/etc/ssmtp/ssmtp.conf` under `/etc/ssmtp/ssmtp_blinker.conf`
5. Add the following option to `/etc/ssmtp/ssmtp_blinker.conf`

   ```
   FromLineOverride=YES
   ```
6. Create a sendmail wrapper to use the alternative config file
   * `mkdir -p /home/blinker-admin/blinker_sendmail`
   * `touch /home/blinker-admin/blinker_sendmail/sendmail`
   * `chmod 755 /home/blinker-admin/blinker_sendmail/sendmail`
   * &nbsp;
     ```
     cat > /home/blinker-admin/blinker_sendmail/sendmail <<EOF
     #!/bin/bash

     exec /usr/sbin/sendmail -C/etc/ssmtp/ssmtp_blinker.conf "$@"
     EOF
     ```

### Blinker-web
1. Obtain the pgp public key generated on `prod-mgmt`
2. `apt-key add package-signing.pub`
3. Add the infra repo to the APT source list
   * `echo 'deb http://prod-mgmt:8080/infra xenial main' > /etc/apt/sources.list.d/prod-mgmt-infra.list`
4. `apt-get update`
5. Install the `blinker-web` package
6. Set permissions on `/etc/blinker/web.yml`
   * `chown root:blinker /etc/blinker/web.yml`
   * `chmod 640 /etc/blinker/web.yml`
7. Edit `/etc/blinker/web.yml`

   ```
   environment: production
   bind: 127.0.0.1
   port: 4567
   survey_token: TBD
   ctf_token: TBD
   priv_db:
     host: prod-db
     dbname: priv
     user: blinker_web
     password: TBD
   anon_db:
     host: prod-db
     dbname: anon
     user: blinker_web
     password: TBD
   mail:
     from: "Help gsx Get His Degree <noreply@help-gsx-get-his-degree.com>"
     reply_to: "contact@help-gsx-get-his-degree.com"
   exceptions_dir: /var/lib/blinker/exceptions
   allow_skip: true
   ```
8. Setup blinker-web to use the sendmail wrapper created earlier

   ```
   patch /etc/supervisor/conf.d/blinker-web.conf <<EOF
   --- /etc/supervisor/conf.d/blinker-web.conf	2017-01-22 12:59:03.803809994 +0000
   +++ /etc/supervisor/conf.d/blinker-web.conf	2017-01-22 14:04:25.961196530 +0000
   @@ -1,5 +1,5 @@
    [program:blinker-web]
    command = blinker-web
    user = blinker
   -environment = BLINKER_WEB_CONFIGFILE="/etc/blinker/web.yml"
   +environment = BLINKER_WEB_CONFIGFILE="/etc/blinker/web.yml",PATH="/home/blinker-admin/blinker_sendmail:%(ENV_PATH)s"
    startsecs = 10
   EOF
   ```
9. Add the following to `/etc/sudoers`

   ```
   # nagios may get the status of supervisord processes
   nagios4-nrpe	ALL = (root) NOPASSWD:/usr/bin/supervisorctl status
   ```
10. `systemctl restart supervisor`

## The ctf server

Let us call it `prod-ctf-1`.

1. Obtain the `package-signing.pub` generated on `prod-mgmt`
2. `apt-key add package-signing.pub`
3. Add the infra repo to the APT source list
   * `echo 'deb http://prod-mgmt:8080/infra xenial main' > /etc/apt/sources.list.d/prod-mgmt-infra.list`
4. `apt-get update`
5. Install the `blinker-ctf` package
6. Set permissions on `/etc/blinker/ctf.yml`
   * `chown root:blinker /etc/blinker/ctf.yml`
   * `chmod 640 /etc/blinker/ctf.yml`
7. Edit `/etc/blinker/ctf.yml`

   ```
   db:
     host: prod-db
     dbname: anon
     user: blinker_ctf
     password: TBD
   challenges_dir: /usr/share/blinker/challenges
   filestore:
     api: http://prod-mgmt:8000/
     public: https://help-gsx-get-his-degree.com/handout/
   aptly:
     api: http://prod-mgmt:8081/
     challenges_repo: challenges
   azure:
     client_id: TBD
     client_secret: TBD
     tenant_id: TBD
     subscription_id: TBD
     resource_group: challenges-vms
     challenge_domain: challenge.help-gsx-get-his-degree.com
     ssh_key: /etc/blinker/root.pub
     provision_script: http://prod-mgmt:8000/provision
   ```
7. Add the following to `/etc/sudoers`

   ```
   # nagios may get the status of supervisord processes
   nagios4-nrpe	ALL = (root) NOPASSWD:/usr/bin/supervisorctl status
   # blinker may use the capture script
   blinker	ALL = (root) NOPASSWD:/opt/blinker/capture.py
   ```
8. Place the SSH public key generated on prod-mgmt under `/etc/blinker/root.pub`.
9. `systemctl restart supervisor`
