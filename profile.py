"""An example of constructing a profile with install and execute services. 

Instructions:
Wait for the profile instance to start, then click on the node in the topology
and choose the `shell` menu item. The install and execute services are handled
automatically during profile instantiation, with no manual intervention required.
"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as rspec

# Create a request object
request = portal.context.makeRequestRSpec()

# Add a raw PC to the request
node = request.RawPC("node")

# Request an image for this node
node.disk_image = "urn:publicid:IDN+emulab.net+image+emulab-ops//CENTOS7-64-STD"

# Install and execute startup scripts
node.addService(rspec.Execute(shell="sh", command="sudo -u root /local/repository/install.sh | tee /local/logs/install.log"))

portal.context.printRequestRSpec()


