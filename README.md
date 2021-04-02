# Installing OnDemand and Keycloak 

### Setup and Configuration

To start up an instance, log in to CloudLab and create a new experiment using the `slate-open-ondemand` profile

1. First SSH into both nodes and go to the `/local` directory.
2. Wait for yum update to finish on both hosts, you have to manually delete these processes with a kill -9 PID command since they get stuck on cleanup. Use `watch tail /local/logs/install.log` and wait until it stops at `Cleanup 420/420`. Then use `ps aux | grep yum` to get the process ID.
3. When the process is killed wait for both scripts to finish before proceeding futher.
4. Run the `ondemand_config.sh` and `keycloak_config.sh` scripts on each host and input your email to get up letsencrypt certs. When running the OnDemand script, use the DNS name of the node which should be visible in the CloudLab portal.
5. When that's done, you should be able to see Open OnDemand and Keycloak at `https://ondemand.example.host` and `https://keycloak.example.host`. To get the hostname aliases, run the `hostname` command in the terminal.

### Keycloak Authentication

Access the Keycloak GUI and log in with the user `admin` and the admin password stored by root. Then go to the Ondemand realm and to set up the client. First createa a test user by going to the `users` tab and give it a password by clicking on credentials, entering a password, and clicking save password with the `temporary password` field set to OFF. 

Next go to the `clients` tab and elect the ondemand_client, and click on the `credentials` tab to get the client-secret. Then in the terminal for the OnDemand host, edit the file at `/opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf` and input the client-secret like so:

```bash
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

When that's done save the file and restart apache using `systemctl restart httpd24-httpd`.
