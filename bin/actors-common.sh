#!/bin/bash
# 
# actors-common.sh
# 
# author: dooley@tacc.utexas.edu
#
# URL filter for actors services
#

filter_service_url() {
	if [[ -z $hosturl ]]; then
		if ((development)); then 
			hosturl="$devurl/actors/"
		else
			hosturl="$baseurl/actors/v1/"
		fi
	fi
}

