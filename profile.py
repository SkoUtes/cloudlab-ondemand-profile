"""An instance for testing SLATE Open OnDemand features and changes

Instructions:
Wait for the profile instance to start, then ssh into both of the nodes
and follow the instructions outlined in the README.md file
"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as rspec
# Import igext module
import geni.rspec.igext as ig

# Create a request object
request = portal.context.makeRequestRSpec()

# Create a portal context to define parameters
pc = portal.Context()

# Create two nodes
node1 = request.RawPC("node1")
node2 = request.RawPC("node2")
node3 = request.RawPC("node3")

# Request an image for this node
node1.disk_image = "urn:publicid:IDN+emulab.net+image+emulab-ops//CENTOS7-64-STD"
node2.disk_image = "urn:publicid:IDN+emulab.net+image+emulab-ops//CENTOS7-64-STD"
node3.disk_image = "urn:publicid:IDN+emulab.net+image+emulab-ops//CENTOS7-64-STD"

# Install and execute startup scripts
node1.addService(rspec.Execute(shell="sh", command="sudo -u root chmod 700 \
	/local/repository/automated_scripts/ondemand.sh && \
	sudo -u root chmod 700 /local/repository/desktop_app_config.sh && \
	sudo -u root chmod 700 /local/repository/automated_scripts/kill_script.sh && \
	sudo -u root /local/repository/automated_scripts/kill_script.sh & disown && \
	sudo -u root chmod 700 /local/repository/ondemand_config.sh && \
	sudo -u root /local/repository/automated_scripts/ondemand.sh"))
node2.addService(rspec.Execute(shell="sh", command="sudo -u root chmod 700 \
	/local/repository/automated_scripts/keycloak.sh && \
	sudo -u root chmod 700 /local/repository/automated_scripts/kill_script.sh && \
	sudo -u root /local/repository/automated_scripts/kill_script.sh & disown && \
	sudo -u root chmod 700 /local/repository/keycloak_config.sh && \
	sudo -u root /local/repository/automated_scripts/keycloak.sh"))
node3.addService(rspec.Execute(shell="sh", command="sudo -u root chmod 700 \
	/local/repository/automated_scripts/worker.sh && \
	sudo -u root chmod 700 /local/repository/automated_scripts/kill_script.sh && \
	sudo -u root /local/repository/automated_scripts/kill_script.sh & disown && \
	sudo -u root /local/repository/automated_scripts/worker.sh"))

portal.context.printRequestRSpec()