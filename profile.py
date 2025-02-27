"""OCT Alveo U280 profile with post-boot script
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

# Function for creating VM guests with common parameters
def mkVM(pnode, name):
    node = request.XenVM(name)
    node.disk_image = "urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU20-64-STD";
    node.cores = 4
    node.ram = 4096
    node.exclusive = True
    #
    # This is the crux of the biscuit; tell the mapper exactly where to place the VM.
    #
    node.InstantiateOn(pnode)
    return node

# Create a portal context.
pc = portal.Context()

# Create a Request object to start building the RSpec.
request = pc.makeRequestRSpec()

# Pick your image.
imageList = [('urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU20-64-STD', 'UBUNTU 20.04'),
             ('urn:publicid:IDN+emulab.net+image+emulab-ops//UBUNTU22-64-STD', 'UBUNTU 22.04')] 

workflow = ['Vitis', 'Vivado']

toolVersion = ['2023.1', '2023.2'] 
                   
pc.defineParameter("workflow", "Workflow",
                   portal.ParameterType.STRING,
                   workflow[0], workflow,
                   longDescription="For Vitis application acceleration workflow, select Vitis. For traditional workflow, select Vivado.")   

pc.defineParameter("toolVersion", "Tool Version",
                   portal.ParameterType.STRING,
                   toolVersion[0], toolVersion,
                   longDescription="Select a tool version. It is recommended to use the latest version for the deployment workflow. For more information, visit https://www.xilinx.com/products/boards-and-kits/alveo/u280.html#gettingStarted")   
pc.defineParameter("osImage", "Select Image",
                   portal.ParameterType.IMAGE,
                   imageList[0], imageList,
                   longDescription="Supported operating systems are Ubuntu and CentOS.")  
 
                   
# Retrieve the values the user specifies during instantiation.
params = pc.bindParameters()        

# Check parameter validity.
  
pc.verifyParameters()

host = request.RawPC("host")
host.hardware_type = "fpga-alveo"
host.disk_image = params.osImage
vm1 = mkVM(host, "vm1");
    
    
host.addService(pg.Execute(shell="bash", command="sudo /local/repository/post-boot.sh " + params.workflow + " " + params.toolVersion + " >> /local/logs/output_log.txt"))
vm1.addService(pg.Execute(shell="bash", command="sudo /local/repository/post-boot.sh " + params.workflow + " " + params.toolVersion + " >> /local/logs/output_log.txt"))


# Print Request RSpec
pc.printRequestRSpec(request)
