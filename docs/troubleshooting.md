# Networking

**ifconfig** ~ *Displays the network interface details like IP addresses, netmasks, ans MAC addresses.*

	ifconfig
---
 
 **ip -a** ~ *Displays detailed information about all network interfaces including IP addresses, Mac addresses, and interface states.*
 
	ip -a
 ---
 
**netstat** ~ *Displays active network connections, listening ports, and routing tables.*
 
	netstat
 ---
 
**/etc/dnsmasq.conf** ~ *Location of DHCP, DNS, and TFTP configuration fil for server*
 
	sudo nano /etc/dsnmasq.conf
 ---

 **ping** ~ *Sends ICMP echo requests to a target host to check network connectivity and measure round-trip time.*
 
	ping
 ---
 **traceroute** ~ *Shows the path packets take to reach a destination, displaying each hop along the way.*
 
	traceroute
---


# NFS and Storage

**mount and umount** ~ *Attatches or detatches a specific directory.*

	mount and umount
---

 **fsck** ~ *Checks and repairs file system integrity*
 
	fsck
---

**chmod** ~ *Changes the permissions of a file or directoty, allowing you to control read, write and access for useres, groups and others.*

	chmod
---

**chown** ~ *Changes the owner and group of a file or directory. Useful for managing file permissions and ownership on multi-user systems.*
 
 	chown
  ---

# Backups and Recovery

**rsync** ~ *Syncronizaties files and directories between two locations, either locally or over a network.*

	rsync

---

 **sd card copier** ~ *Useful for making full backups of the system*
 
---

# Logs

**syslog** ~ *A standard for logging system messages and events. Provides a central repository for log files.*

	syslog

 ---

**dmseg** ~ *Displays kernel ring buffer messages, which include system startup messages and hardware related logs.*

	dmesg
