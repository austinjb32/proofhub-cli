#!/bin/bash

echo -e "\033[1m\033[0m"
echo -e "$(tput bold)$(tput setaf 9) Welcome to Proofhub Project Intialization - By Austin Jacob"$(tput sgr0)
read -p "Enter Proofhub Email: " proofhub_email
read -p "Enter Proofhub API Key: " proofhub_api_key

get_selected_project_id() {
    local options=()
    local titles=()
    local index=1
   echo -e "\033[1mSelect Proofhub Project\033[0m"
    while read -r entry; do
        title=$(echo "$entry" | jq -r '.title')
        id=$(echo "$entry" | jq -r '.id')

       echo "$index. $title"
        options+=("$id")  
        titles+=("$title")
        ((index++))
    done < <(curl -s --location 'https://hubspire.proofhub.com/api/v3/projects/' \
        --header "User-Agent: $proofhub_email" \
        --header "x-api-key: $proofhub_api_key" | jq -c '.[] | {title: .title, id: .id}')


    read -p "$(tput bold)$(tput setaf 8) Enter the number of the title you want to select: $(tput sgr0)" selected_index

  
    if [[ ! "$selected_index" =~ ^[1-9][0-9]*$ || "$selected_index" -gt "${#options[@]}" ]]; then
        echo "Invalid selection. Please enter a valid number."
        exit 1
    fi

      selected_id="${options[selected_index-1]}"
    selected_title="${titles[selected_index-1]}"
    echo "You selected $selected_title with ID: $selected_id"

  
    echo '{
      "API_ENDPOINT": "https://hubspire.proofhub.com/api/v3/projects/'"$selected_id"'",
      "USER_AGENT": "'"$proofhub_email"'",
      "API_KEY": "'"$proofhub_api_key"'"
    }' > proofhub.json

echo -e "$(tput bold)$(tput setaf 10) proofhub.json created successfully!"$(tput sgr0)
}

get_selected_project_id

