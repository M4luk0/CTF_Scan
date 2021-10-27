#!/bin/bash
# CTF Scan
# Copyright: Juan Antonio Gil Chamorro (M4luk0)

# Advice
echo "Hello everyone, I'm going to explain what you need to use this tool; you need to have nmap, rustscan, whatweb and ffuf installed; besides having them in /usr/bin/, enjoy the tool! (the console will show some errors like rm and grep: null; don't pay attention to that)"

echo ""

# Request the necessary information for the execution.
read -p "Introduce IP/s or host/s: " IP

echo ""

echo "What wordlist do you want to use? /usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt it's the default wordlist"
echo "Put . if you want the default wordlist"
echo "Introduce Path to the wordlist you want"
read -p "Select the option you want: " wordlist
case $wordlist in
.)
        wordlistFile=/usr/share/wordlists/dirbuster/directory-list-2.3-medium.txt
        ;;
*)
        wordlistFile=$wordlist
        ;;
esac

echo ""

echo "What wordlist do you want to use for subdomain search? /usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt it's the default wordlist"
echo "Put . if you want the default wordlist"
echo "Introduce Path to the wordlist you want"
read -p "Select the option you want: " wordlist
case $wordlist in
.)
        subWordlistFile=/usr/share/wordlists/seclists/Discovery/DNS/subdomains-top1million-110000.txt
        ;;
*)
        subWordlistFile=$wordlist
        ;;
esac

echo ""

echo "Do you want to skip any step? you won't have any record of them in info.txt"
read -p "Type 'y' or 'n': " anyStep
case $anyStep in
y)
       	echo "Wich steps do you want to skip? enter as many options as you want. example: sdw"
       	echo "p for skip port scan"
       	echo "d for skip directory search"
       	echo "s for skip subdomains search"
       	echo "w for skip whatweb tool"
       	read -p "Introduce flags: " skip
	echo $skip > /tmp/file.txt
	skipStep=/tmp/file.txt
	;;
n)
       	skipStep="null"
       	echo "Ok, let's go to another question."
	;;
esac

echo ""

echo "Where do you want to save info.txt file?"
echo "Put . if you want the actual directory"
echo "Introduce Path to the directory you want"
read -p "Select the option you want: " infoLocation
infoFile=$infoLocation/info.txt

echo ""

echo "Thanks, your scan is in proccess now, you can view all the info in info.txt file."

# Create an info document with information about the IP we have analyzed in addition to my own IP for possible reverse shell.
rm $infoFile
touch $infoFile
echo "IP/s or host/s: $IP" >> $infoFile

echo "Own IP: $(ifconfig tun0 | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)" >> $infoFile


# Scanning of the 65535 ports of the specified IP.
echo ""

if grep "p" $skipStep;
then
        echo "Skipping port scan..."
else
        echo "Starting port scan... to view the result before it finish, read info.txt file."

        echo "" >> $infoFile
        echo "Scanner:" >> $infoFile

	/usr/bin/rustscan -r 1-65535 -u 5000 -a $IP -- -sC -sV -Pn >> $infoFile

        echo "Port scan finish!"
fi


# Search directories.
echo ""

if grep "d" $skipStep;
then
        echo "Skipping directory search..."
else
        echo "Starting Directory search... to view the result before it finish, read info.txt file."

        echo "" >> $infoFile
        echo "Directory list:" >> $infoFile

	if grep "ssl" $infoFile;
        then
		/usr/bin/ffuf -w $wordlistFile:FUZZ -u https://$IP/FUZZ -t 200 -e .txt,.php,.bak,.conf -fc 404 >> $infoFile
        else
		/usr/bin/ffuf -w $wordlistFile:FUZZ -u http://$IP/FUZZ -t 200 -e .txt,.php,.bak,.conf -fc 404 >> $infoFile
        fi

        echo "Directory search finish!"
fi

# Search subdomains.
echo ""

if grep "s" $skipStep;
then
        echo "Skipping subdomains search..."
else
        echo "Starting Subdomains search... to view the result before it finish, read info.txt file."

        echo "" >> $infoFile
        echo "Subdomains list:" >> $infoFile

        if grep "ssl" $infoFile;
        then
        	/usr/bin/ffuf -w $subWordlistFile:FUZZ -u https://FUZZ.$IP/ -t 200 -fc 404 >> $infoFile

		echo "" >> $infoFile
		echo "VHosts List:" >> $infoFile
		/usr/bin/ffuf -w $subWordlistFile:FUZZ -u https://$IP/ -H 'Host: FUZZ.' + $IP -t 200 -fc 404 >> $infoFile
        else
                /usr/bin/ffuf -w $subWordlistFile:FUZZ -u http://FUZZ.$IP/ -t 200 -fc 404 >> $infoFile

        	echo "" >> $infoFile
                echo "VHosts List:" >> $infoFile
                /usr/bin/ffuf -w $subWordlistFile:FUZZ -u http://$IP/ -H 'Host: FUZZ.' + $IP -t 200 -fc 404 >> $infoFile
	fi

        echo "Subdomains search finish!"
fi

# Use whatweb tool.
echo ""

if grep "w" $skipStep;
then
        echo "Skipping whatweb..."
else
	echo "Starting whatweb... to view the result before it finish, read info.txt file."

	echo "" >> $infoFile
	echo "Whatweb:" >> $infoFile

	if grep "ssl" $infoFile;
	then
        	/usr/bin/whatweb https://$IP >> $infoFile
	else
        	/usr/bin/whatweb http://$IP >> $infoFile
	fi
	echo "whatweb finish!"
fi

# End of execution.
echo ""
echo "Your scan is finished, enjoy!"
rm $skipStep
