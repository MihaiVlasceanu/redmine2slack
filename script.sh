#!/bin/bash
# Add your redmine rss key here
redmine_key="";

# Add your slack channel webhook url
slack_url="";

# Redmine URL
redmine_url="";

# Public channel to post updates to
slack_channel="#general";

# Name of the BOT that it will be displayed on slack
slack_username="Redmine";

# Bot icon
slack_bot_icon=':ghost:';

# Vars used in slack call
title="";
project="";
url="";
pub="";
author="";
newstatus="";
issueType="Bug";
issueId=0;

# Read 
rsstail -i 300 -n 0 -alp -u "${redmine_url}/activity.atom?key=${redmine_key}" | while read line; 
do 
    none="";
	if [[ ${line} == "Title"* ]]
	then
	        # Remove The "Title: " part 
	  	txt="${line/Title: /${none}}";
	
	  	# Find the first position of the - character
	  	fd=`expr index "${txt}" \\-`;
	
	  	fic=`expr index "${txt}" \\:`;
	  	
	  	# The projet name is in the first part
	  	let "pend = ${fd} - 2";
	  	project=${txt:0:${pend}};
	  	
	  	# The title is in the second
	  	let "reminder = ${#txt}-${fd}";
	  	let "strstart = ${fd}+1";
	
	  	str=${txt:${strstart}:${reminder}};
	  	title=${txt:${fic}+1:${reminder}};
	
	  	# Match new status e.g. (New)
	  	stsReg='\((.*?)\)';
	  	if [[ $str =~ $stsReg ]]; 
		then 
			newstatus=${BASH_REMATCH[1]};
		fi
	
		# Match issue id e.g. #123
		reg='\#([0-9]+)'
		if [[ $txt =~ $reg ]]; 
		then 
			issueId=${BASH_REMATCH[1]}; 
			iPos=`expr index "${str}" \\#`;
			issueType=${str:0:${iPos}-2};
		fi
	fi

  	# Link to issue
	if [[ ${line} == "Link:"* ]]
	then
		# Remove The "Link: " part 
	  	url="${line/Link: /${none}}";
	fi

  	# Publication date
	if [[ ${line} == "Pub.date:"* ]]
	then
		# Remove The "Link: " part 
	  	pub="${line/Pub.date: /${none}}";
	fi
  
	# Issue author
	if [[ "${line}" == "Author:"* ]];
	then
	
		# This ignores the gitlab-related data
		if [[ ${line} != *"gitlab"* ]];
		then
		
	  		# Remove The "Author: " part 
  			author="${line/Author: /${none}}";
        
        		# Slack call string/payload
   			payload='payload=
	   		{
	 			"channel": "'"${slack_channel}"'",
	 			"username": "'"${slack_username}"'",
	 			"icon_emoji": "'"${slack_bot_icon}"'",
	 			"attachments": [
	 				{
	 				"fallback": "The following issue has been added/updated",
			            	"color": "#36a64f",
					"pretext": "The following issue has been added/updated",
					"author_name": "'"${author}"'",
					"title": "'"${title//\"/\\\"}"'",
					"title_link": "'"${url}"'",
					"fields": [
						{
						    "title": "Status",
						    "value": "'"${newstatus}"'",
						    "short": true
						},
						{
						    "title": "Project",
						    "value": "'"${project}"'",
						    "short": true
						},
						{
							"title": "Type",
						    "value": "'"${issueType}"'",
						    "short": true
						},
						{
							"title": "ID",
						    "value": "'"${issueId}"'",
						    "short": true
						}
		            		]
	 				}
	    			]
			}';
		
			response=$(curl  \
			-H "Accept: application/json" \
			-X POST \
			--data-urlencode "${payload}" \
			"${slack_url}");
			echo $(date +%s) " - " ${payload} ": "${response} >> slack.log
		fi
	fi
done
