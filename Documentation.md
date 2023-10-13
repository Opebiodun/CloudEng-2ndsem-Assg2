## Deployment of Vagrant Ubuntu Cluster with LAMP Stack

This project script will automate the deployment of a Vagrant-based Ubuntu cluster with a LAMP stack, user management, SSH key-based authentication, data transfer, process monitoring, and load balancing.

The documentation outlines the steps for deploying a Vagrant-based Ubuntu cluster with a LAMP (Linux, Apache, MySQL, PHP) stack, comprising a 'Master' and a 'Slave' node.

## Prerequisites

1. **Vagrant:** Ensure that Vagrant is installed. You can download it from (https://www.vagrantup.com/downloads.html).

2. **VirtualBox:** Make sure you have VirtualBox installed, which is one of the supported virtualization providers for Vagrant. You can download it from (https://www.virtualbox.org/).

3. **Run Script:** Run the deployment script to create the Vagrant cluster and set up the LAMP stack:
   (The Script is save with master_slave.sh, make the script executable "chmod +x master_slave.sh")

    ```bash
    ./master_slave.sh
    ```

    This script will perform the following actions:
    
    - Check for Vagrant and VirtualBox installation
    - Create Clusterlamp Directory 
    - Initialized and Install Vagrant if not available
    - Generate an SSH key if missing.
    - Configure SSH key-based authentication between the 'Master' and 'Slave'.
    - Copy test data from 'Master' to 'Slave'.
    - Install the LAMP stack on both nodes.
    - Display the process overview on 'Master'.

4. **Access the Nodes:**

    - To access the 'Master' node:
    
        ```bash
        vagrant ssh master
        ```

    - To access the 'Slave' node:
    
        ```bash
        vagrant ssh slave
        ```
    
    - To access the 'Slave' from Master node or from altschool user
    
        ```bash
        ssh vagrant@192.168.33.12 (Note - if it prompt ARE YOU SURE YOU WANT TO CONNECT, type "yes" and input "vagrant" as passowrd when required) 
        ```
    
5. **Validate LAMP Stack:**

    - Open a web browser and enter the IP address of either 'Master' or 'Slave' followed by `/info.php`, e.g., `http://192.168.33.12/info.php`. You should see the PHP information page, confirming the LAMP stack's functionality.

## Cleanup

To stop and destroy the Vagrant environment:

```bash
vagrant halt
vagrant destroy 
