# Installing OnDemand and Keycloak 

### Setup and Configuration

To start up an instance, log in to CloudLab and create a new experiment using the `slate-open-ondemand` profile.

1. First SSH into both nodes and go to the `/local/logs` directory.
2. Use `watch tail install.log` to monitor the progress of the installation. When it's completed use `certbot --version` to make sure that certbot is installed, and then switch to the root user with `sudo -i`.
3. In the `/local/repository` directory, run the `ondemand_config.sh` script on node1 and `keycloak_config.sh` script on node2. Follow the prompts and input your email to get up letsencrypt certs. When running the OnDemand script, use the FQDN of the node which should be visible in the CloudLab portal.
4.   When that's done, you should be able to see Open OnDemand and Keycloak at `https://ondemand.example.host` and `https://keycloak.example.host`. To get the hostname aliases, run the `hostname` command in the terminal.

### Keycloak Authentication

Access the Keycloak GUI and log in with the user `admin` and the admin password stored in the `/root` directory. Then go to the Ondemand realm and to set up the client. First create a a test user by going to the `users` tab and give it a password by clicking on credentials, entering a password, and clicking save password with the `temporary password` field set to OFF. Then, go to the OnDemand terminal and create a user with the same name and password using:

```bash
useradd "test-user"
passwd test-user
```

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

Then save the file and restart apache using `systemctl restart httpd24-httpd`. Then to check if your setup is correct, go to `https://ondemand.example.host` and see if you can log in with your test user.
