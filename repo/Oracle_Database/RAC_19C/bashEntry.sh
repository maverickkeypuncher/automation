

exec 1> /tmp/command.log 2>&1


cat << EOF >> /oracle/.bash_profile 


# .bash_profile
umask 0022

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/bin:/usr/bin

export PATH
export PS1='[\u@\h:$ ] '
# Oracle Environment
# Oracle Environment
clear
# RAC Setup
umask 022
ulimit -f unlimited
n1=$1
n2=$2

alias sysdba='sqlplus / as sysdba'
echo ' '
echo '#######################################################'
echo "## There are folloing Two instances running on this system"
echo " "
echo "## Please load the correspoing profiles seperately."
echo ' '
echo "1.  ASM     ------> bash_profile_ASM "
echo "2.  ODSDR ------> bash_profile_DBName "

echo -e '\n####################################################'

EOF

cat << EOF >> /oracle/.bash_profile_ASM
unset ORACLE_HOME

# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc: ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs


export PS1='[\u@\h:$ ] '

# User specific environment and startup programs

# Oracle Environment
clear
# RAC Setup
umask 022
#ulimit -n 1024
#ulimit -n 65536
#ulimit -u 2048
ulimit -f unlimited

ORACLE_BASE=/oragrid/grid_base;export ORACLE_BASE
ORACLE_HOME=/oragrid/app/product/19.3.0/grid_1;export ORACLE_HOME
ORACLE_SID=+ASM1;export ORACLE_SID
ORACLE_TERM=xterm;export ORACLE_TERM

# Set shell search paths:
export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch
clear
env | grep  ORA

EOF

cat << EOF >> /oracle/.bash_profile_DBName

unset ORACLE_HOME
# .bash_profile

# Get the aliases and functions
if [ -f ~/.bashrc: ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=/usr/local/bin:/usr/bin/:/usr/local/sbin:/usr/sbin:/bin
export PATH

export PS1='[\u@\h:$ ] '

# User specific environment and startup programs

# Oracle Environment
clear
# RAC Setup
umask 022
#ulimit -n 1024
#ulimit -n 65536
#ulimit -u 2048
ulimit -f unlimited

alias sysdba='sqlplus / as sysdba'


ORACLE_BASE=/oracle/app;export ORACLE_BASE
ORACLE_HOME=/oracle/app/product/19.3.0/dbhome_1;export ORACLE_HOME
ORACLE_SID=DBName;export ORACLE_SID
ORACLE_TERM=xterm;export ORACLE_TERM
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib


export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch

clear
env | grep  ORA

EOF

cat << EOF >> /oracle/.bash_profile_org

# .bash_profile
umask 0022

# Get the aliases and functions
if [ -f ~/.bashrc ]; then
        . ~/.bashrc
fi

# User specific environment and startup programs

PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin

export PATH

# Oracle Environment

alias sysdba='sqlplus / as sysdba'
echo "Select Oracle SID"
echo "1.  ASM"
echo "2.  itmprod"

read orvar

case "$orvar" in
1)
unset ORACLE_HOME
#ORACLE_BASE=/oracle/app;export ORACLE_BASE
ORACLE_HOME=/oragrid/app/product/19.3.0/grid_1;export ORACLE_HOME
ORACLE_SID=+ASM1;export ORACLE_SID
ORACLE_TERM=xterm;export ORACLE_TERM

# Set shell search paths:
export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch
#export PATH=/oragrid/app/product/19.3.0/grid_1/perl/bin
clear
env | grep  ORA
;;


2)
unset ORACLE_HOME
ORACLE_BASE=/oracle/app;export ORACLE_BASE
ORACLE_HOME=/oracle/app/product/19.3.0/dbhome_1;export ORACLE_HOME
ORACLE_SID=duaedr1;export ORACLE_SID
ORACLE_TERM=xterm;export ORACLE_TERM
export LD_LIBRARY_PATH=$ORACLE_HOME/lib:/lib:/usr/lib

export PATH=$PATH:$ORACLE_HOME/bin:$ORACLE_HOME/OPatch

#clear
env | grep  ORA
;;

*)
        echo "You did not choose an environment! No Oracle parameters set!"
esac


EOF

node1=$1
node2=$2

sshpass -p 'oracle' scp /oracle/.bash_profile oracle@$node2:/oracle/
sshpass -p 'oracle' scp /oracle/.bash_profile_org oracle@$node2:/oracle/
sshpass -p 'oracle' scp /oracle/.bash_profile_ASM oracle@$node2:/oracle/
sshpass -p 'oracle' scp /oracle/.bash_profile_DBName oracle@$node2:/oracle/
sshpass -p 'oracle' ssh oracle@$node2 'sed -i s/+ASM1/+ASM2/g' /oracle/.bash_profile_org
sshpass -p 'oracle' ssh oracle@$node2 'sed -i s/+ASM1/+ASM2/g' /oracle/.bash_profile_ASM

rm -- "$0"
rm -frv /OracleRAC19C
sshpass -p 'Passwd!1' ssh sysadm@$node2 'sudo rm -frv /OracleRAC19C'
if [ $? -eq 0 ]; then
{
	echo "0" > /tmp/cluststat
	sudo chmod 777 /tmp/cluststat
}
fi

mv -f /usr/bin/scp.original /usr/bin/scp

