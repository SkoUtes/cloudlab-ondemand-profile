
# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as rspec

# Create a request object
request = portal.context.makeRequestRSpec()

# Add a raw PC to the request
node = request.RawPC("Open_OnDemand")

# Request an image for this node
node.disk_image = "urn:publicid:IDN+emulab.net+image+emulab-ops//CENTOS7-64-STD"

# Install and execute startup scripts
node.addService(rspec.Execute(shell="bash", command="/local/repository/install.sh"))

portal.context.printRequestRSpec()


