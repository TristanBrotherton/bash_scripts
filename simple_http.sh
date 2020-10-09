simple_http() {
	
    if [[ -n $1 ]] ; then
        port="$1"
    else
        port="8000"
    fi
	#python -m SimpleHTTPServer ${port} &> /dev/null &
	(python -m SimpleHTTPServer ${port} &) &> /dev/null
	#read < <( python -m SimpleHTTPServer ${port} & echo $! )
	#echo "PID is: $REPLY"
    echo "http://localhost:${port}"
    echo -n "Is this a good question (y/n)? "
    read answer

    
}
