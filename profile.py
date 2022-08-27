"""Configure FPGA nodes using a post-boot script.
"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
"""fpga 
"""

# Import the Portal object.
import geni.portal as portal
# Import the ProtoGENI library.
import geni.rspec.pg as pg
# We use the URN library below.
import geni.urn as urn
# Emulab extension
import geni.rspec.emulab

# Create a portal context.
pc = portal.Context()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

# Variable number of nodes.
pc.defineParameter("nodeCount", "Number of Nodes", portal.ParameterType.INTEGER, 1,
                   longDescription="Enter the number of FPGA nodes. Maximum is 16.")

# Pick your image.
imageList = [
    #('urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU20-64-STD', 'UBUNTU 20.04'),    
    ('urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU18-64-STD', 'UBUNTU 18.04'), 
    ('urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU16-64-STD', 'UBUNTU 16.04'),
    #('urn:publicid:IDN+emulab.net+image+emulab-ops//CENTOS8-64-STD', 'CENTOS 8.4'),
    ('urn:publicid:IDN+emulab.net+image+emulab-ops//CENTOS7-64-STD', 'CENTOS 7.9')] 

toolVersion = [#('2022.1'),
               ('2021.1'), 
               ('2020.2.1'), 
               ('2020.2'), 
               ('2020.1.1'),
               ('2020.1'),
               ('Do not install tools')]      
                   
pc.defineParameter("toolVersion", "Tool Version",
                   portal.ParameterType.STRING,
                   toolVersion[0], toolVersion,
                   longDescription="Select a tool version. It is recommended to use the latest version for the deployment workflow. For more information, visit https://www.xilinx.com/products/boards-and-kits/alveo/u280.html#gettingStarted")   
pc.defineParameter("osImage", "Select Image",
                   portal.ParameterType.IMAGE,
                   imageList[0], imageList,
                   longDescription="Supported operating systems are Ubuntu and CentOS.")                    
# Optional ephemeral blockstore
pc.defineParameter("tempFileSystemSize", "Temporary Filesystem Size",
                   portal.ParameterType.INTEGER, 0,advanced=True,
                   longDescription="The size in GB of a temporary file system to mount on each of your " +
                   "nodes. Temporary means that they are deleted when your experiment is terminated. " +
                   "The images provided by the system have small root partitions, so use this option " +
                   "if you expect you will need more space to build your software packages or store " +
                   "temporary files.")
# Instead of a size, ask for all available space. 
pc.defineParameter("tempFileSystemMax",  "Temp Filesystem Max Space",
                    portal.ParameterType.BOOLEAN, False,
                    advanced=True,
                    longDescription="Instead of specifying a size for your temporary filesystem, " +
                    "check this box to allocate all available disk space. Leave the size above as zero.")

pc.defineParameter("tempFileSystemMount", "Temporary Filesystem Mount Point",
                   portal.ParameterType.STRING,"/mydata",advanced=True,
                   longDescription="Mount the temporary file system at this mount point; in general you " +
                   "you do not need to change this, but we provide the option just in case your software " +
                   "is finicky.")  
                   
# Retrieve the values the user specifies during instantiation.
params = pc.bindParameters()        

# Check parameter validity.

if params.nodeCount < 1 or params.nodeCount > 16:
    pc.reportError(portal.ParameterError("The number of FPGA nodes should be greater than 1 and less than 16.", ["nodeCount"]))
    pass
if params.osImage == "urn:publicid:IDN+emulab.net+image+emulab-ops//CENTOS8-64-STD" and params.toolVersion == "2020.1":
    pc.reportError(portal.ParameterError("OS and tool version mismatch.", ["osImage"]))
    pass
  
pc.verifyParameters()

# lan = request.LAN()

# Process nodes, adding to FPGA network
for i in range(params.nodeCount):
    # Create a node and add it to the request
    name = "node" + str(i)
    node = request.RawPC(name)
    node.disk_image = params.osImage
    # Assign to the node hosting the FPGA.
    node.hardware_type = "fpga-alveo"
    node.component_manager_id = "urn:publicid:IDN+cloudlab.umass.edu+authority+cm"
    
    # Optional Blockstore
    if params.tempFileSystemSize > 0 or params.tempFileSystemMax:
        bs = node.Blockstore(name + "-bs", params.tempFileSystemMount)
        if params.tempFileSystemMax:
            bs.size = "0GB"
        else:
            bs.size = str(params.tempFileSystemSize) + "GB"
            pass
        bs.placement = "any"
        pass
    
    if params.toolVersion != "Do not install tools":
        node.addService(pg.Execute(shell="bash", command="sudo /local/repository/post-boot.sh " + params.toolVersion + " >> /local/repository/output_log.txt"))
        pass 
    pass
pc.printRequestRSpec(request)
