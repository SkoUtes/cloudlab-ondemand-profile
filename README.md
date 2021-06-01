# Installing Open OnDemand with Keycloak Authentication and LinuxHost Adapter

### Setup and Configuration

To start up an instance, log in to CloudLab and create a new experiment using the `slate-open-ondemand` profile.

1. First SSH into all three nodes and wait for `node1` and `node2` to finish their startup scripts. These nodes are for Open OnDemand and Keycloak respectively.
2. Use `watch tail /local/logs/install.log` to monitor the progress of installation on each node. When it's completed use `certbot --version` to make sure that certbot is installed, and then switch to the root user with `sudo -i`.
3. On node1 run the command `/local/repository/ondemand_config.sh` and on node2 run `/local/repository/keycloak_config.sh`. When prompted enter your email and to input a DNS name, type `hostname -A` in the terminal of the requested node.
4.   When that's done, you should be able to see Open OnDemand and Keycloak at `https://ondemand.example.host` and `https://keycloak.example.host`. To get the hostname aliases, run the `hostname` command in the terminal.

### Keycloak Authentication

Access the Keycloak GUI and log in with the user `admin` and the admin password stored in the `/root` directory. After logging in switch to the `ondemand` realm by selecting it from the drop-down menu on the top left. Next create a test user by going to the `users` tab and give it a password by clicking on credentials, entering a password, and clicking save password with `temporary password` set to OFF. Then, go to the OnDemand terminal and create a user with the same name and password using:

```bash
useradd "test"
passwd test
```

Now go to the `clients` tab and select the ondemand_client. Click on the `credentials` menu to see the client-secret. In the terminal for the OnDemand host, edit the file at `/opt/rh/httpd24/root/etc/httpd/conf.d/auth_openidc.conf` and input the client-secret like so:

```bash
OIDCProviderMetadataURL https://keycloak_hostname/auth/realms/ondemand/.well-known/openid-configuration
OIDCClientID        "ondemand_client"
OIDCClientSecret    "client-secret"
OIDCRedirectURI      https://ondemand_hostname/oidc
OIDCCryptoPassphrase "openssl_random_hex"

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

Then save the file and restart apache using `systemctl restart httpd24-httpd`. Use the `hostname` command to get the URL for the OnDemand server and try accessing it through your browser. It will warn you that the certificate is invalid, but this is not a concern since the server is actually encrypted through the DNS name, so tell your browser to trust the certificate. 

If you can successfully log in then you know that Keycloak authentication is working and your connection is secure.

### Configure LinuxHost Adapter

On the OnDemand node run `/local/repository/dekstop_app_config.sh` and enter the information requested from node3. When that's done run `showmount -e` to check if nfs properly exported the user home directories.

On node3 (the compute node) run `/local/repository/worker_config.sh` as the root user and input information requested from node1. Type `ls /home` to check if the user directories are mounted. Then create a test user with the same name and password as the one stored in the Keycloak database and the OnDemand server.

To check if the LinuxHost Adapter is working, first try accessing the node3 from the OnDemand web GUI by selecting it under the `Clusters` menu. Then try starting up a remote desktop session on node3 by selecting it under the `Interactive Apps` menu. If everything is working properly then you should have a passwordless connection and a mate desktop in your browser window.