#!/bin/bash

#source /oracle/.bash_profile
node2=$1
#patchDIR="/opt/18370031"


## Below command will patch the current version
#su - oracle -c 'echo "passw0rd!" | echo Y | /oragrid/app/product/11.2.0.4/grid_1/OPatch/opatch apply -oh /oragrid/app/product/11.2.0.4/grid_1 -local '$patchDIR''
#if [ $? -eq 0 ]; then
#{
#	echo "Successfully applied patch on $node2"
        mv /oragrid/app/product/12.2.0/grid_1/usm /oragrid/app/product/12.2.0/grid_1/usm_orig
	echo "Executing the root scripts on second node"
        sh /oracle/oraInventory/orainstRoot.sh >> /tmp/dj
        if [ $? -eq 0 ]; then
        {
        	
		sh /oragrid/app/product/12.2.0/grid_1/root.sh >> /tmp/dj
                #sleep 300
                grep "Configure Oracle Grid Infrastructure for a Cluster ... succeeded" /oragrid/app/product/12.2.0/grid_1/install/root_*.log >> /dev/null
                if [ $? -eq 0 ]; then
                {
                	echo "Successfully completed execution of root scripts."
		}
		else
		{
			echo "Error executing root script in second node. Please check manually"
		}
		fi
	}
	else
	{
		echo "Error executing the /oracle/oraInventory/orainstRoot.sh , please execute manually as root user"
	}
	fi
#}
#else
#{
#	echo "Could not apply patch"
#}
#fi

