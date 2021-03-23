# Installing OnDemand and Keycloak 


1. First SSH into both nodes and go to the `/local` directory.
2. Wait for yum update to finish on both hosts, you have to manually delete these processes with a kill -9 PID command since they get stuck on cleanup. Use `watch tail /local/logs/install.log` and wait until it stops at `Cleanup 420/420`. Then use `ps aux | grep yum` to get the process ID.
3. When the process is killed wait for both scripts to finish before proceeding futher
4. To collect certs on the OnDemand host `node1` set your email as an env variable `export email=[Your email]` and run the following command:
```bash
certbot -m $email -d $hostname --agree-tos --apache \
--apache-server-root /opt/rh/httpd24/root/etc/httpd --apache-vhost-root /opt/rh/httpd24/root/etc/httpd/conf.d \
--apache-logs-root /opt/rh/httpd24/root/etc/httpd/logs --apache-challenge-location /opt/rh/httpd24/root/etc/httpd/ \
--apache-ctl /opt/apachectl-wrapper.sh
```
5. Then on the Keycloak host `node2` set your email again as `export email=[Your email]` and run:
```bash
certbot --apache -m $email -d $hostname --agree-tos
```
6. Then run the scripts `ondemand_config.sh` and `keycloak_config.sh` on their respective hosts


#### After this you should be able to access both OnDemand and Keycloak at their CloudLab assigned hostnames.
#### If there is an issue concerning certs you may be past the weekly limit, if so try to renew the old cert, or start up a new instance with a different instance name.