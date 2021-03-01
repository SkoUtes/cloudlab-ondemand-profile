#!/usr/local/python3

import geni.portal as portal
import geni.rspec.pg as pg
import geni.rspec.emulab as emulab
import geni.respec.igext as igext

pc = portal.Context()

request = pc.makeRequestRSpec()

node = request.RawPC("Open_OnDemand")

# Request an image for this node
node.disk_image = "urn:publicid:IDN+emulab.net+image+emulab-ops//CENTOS7-64-STD"

# Install and execute startup scripts
node.addService(rspec.Install())

pc.printRequestRSpec()


