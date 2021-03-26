# Installing OnDemand and Keycloak 


1. First SSH into both nodes and go to the `/local` directory.
2. Wait for yum update to finish on both hosts, you have to manually delete these processes with a kill -9 PID command since they get stuck on cleanup. Use `watch tail /local/logs/install.log` and wait until it stops at `Cleanup 420/420`. Then use `ps aux | grep yum` to get the process ID.
3. When the process is killed wait for both scripts to finish before proceeding futher
4. To collect certs on the OnDemand host `node1` set your email as an env variable `export email=[Your email]` and run the following command:
```bash
certbot -m $email -d $(hostname) --agree-tos --apache \
--apache-server-root /opt/rh/httpd24/root/etc/httpd --apache-vhost-root /opt/rh/httpd24/root/etc/httpd/conf.d \
--apache-logs-root /opt/rh/httpd24/root/etc/httpd/logs --apache-challenge-location /opt/rh/httpd24/root/etc/httpd/ \
--apache-ctl /opt/apachectl-wrapper.sh
```
5. Then on the Keycloak host `node2` set your email again as `export email=[Your email]` and run:
```bash
certbot --apache -m $email -d $(hostname) --agree-tos
```
6. Then run the scripts `ondemand_config.sh` and `keycloak_config.sh` on their respective hosts

#### Setting up Keycloak Authentication

Access the Keycloak GUI and log in with the user `admin` and the admin password stored by root. Go to the ondemand realm, select the ondemand_client, and click on the `credentials` tab to get the client-secret. Then in the terminal for the OnDemand host, edit the file at `/opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf` and input the client-secret like so:

```apacheconf
OIDCProviderMetadataURL https://$kc_host/auth/realms/ondemand/.well-known/openid-configuration
OIDCClientID        "ondemand_client"
OIDCClientSecret    "client-secret"
OIDCRedirectURI      https://$hostname/oidc
OIDCCryptoPassphrase "$(openssl rand -hex 40)"

# Keep sessions alive for 8 hours
OIDCSessionInactivityTimeout 28800
OIDCSessionMaxDuration 28800

# Set REMOTE_USER
OIDCRemoteUserClaim preferred_username

# Don't pass claims to backend servers
OIDCPassClaimsAs environment

# Strip out session cookies before passing to backend
OIDCStripCookies mod_auth_openidc_session mod_auth_openidc_session_chunks mod_auth_openidc_session_0 mod_auth_openidc_session_1
```
