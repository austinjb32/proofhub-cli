#!/bin/bash

api_endpoint=$(jq -r '.API_ENDPOINT' proofhub.json)
user_agent=$(jq -r '.USER_AGENT' proofhub.json)
api_key=$(jq -r '.API_KEY' proofhub.json)

spinner() {
  local pid=$1
    local delay=0.2
    local chars=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        printf "$(tput bold)$(tput setaf 6) %s Loading "$(tput sgr0) "${chars[i]}"
        ((i = (i + 1) % ${#chars[@]}))
        sleep $delay
        printf "\r"
    done

    printf "    \r"
}
timesheets=$(curl -s --location "$api_endpoint/timesheets" \
  --header "User-Agent: $user_agent" \
  --header "x-api-key: $api_key")

echo -e "$(tput bold)$(tput setaf 11) Select Proofhub Timesheet"$(tput sgr0)

selected_timesheet=$(echo "$timesheets" | jq -r '.[].title' | fzf \
  --height=10 \
  --border \
  --prompt="Select a timesheet: " \
) || exit 0

selected_timesheet_id=$(echo "$timesheets" | jq -r --arg title "$selected_timesheet" '.[] | select(.title == $title) | .id')

echo "Selected Timesheet:"$(tput bold)$(tput setaf 9) "${selected_timesheet}" $(tput sgr0)

# Use a subshell to run the spinner function in the background
(spinner $$) & SPINNER_PID=$!

# Perform the second API call
curl -s --location "$api_endpoint/todolists" \
--header "User-Agent: $user_agent" \
--header "x-api-key: $api_key" \
--output data.json

# Kill the spinner once the second API call is complete
kill $SPINNER_PID
wait $SPINNER_PID 2>/dev/null
echo ""



if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Please install it."
    exit 1
fi

echo -e "$(tput bold)$(tput setaf 11) Select Proofhub Todolist"$(tput sgr0)
options=()
index=1
while read -r entry; do
    title=$(echo "$entry" | jq -r '.title')
    id=$(echo "$entry" | jq -r '.id')

    echo "$index. $title"
    titles+=("$title")
    options+=("$id") 
    ((index++))
done < <(jq -c '.[] | {title: .title, id: .id}' data.json)

read -p "$(tput setaf 8)Enter the number of the title you want to select:  $(tput sgr0) " selected_index    

if [[ ! "$selected_index" =~ ^[1-9][0-9]*$ || "$selected_index" -gt "${#options[@]}" ]]; then
    echo "Invalid selection. Please enter a valid number."
    exit 1
fi

selected_id="${options[selected_index - 1]}"

echo "Selected Todolist:"$(tput bold)$(tput setaf 9) "${titles[selected_index-1]}" $(tput sgr0)

(spinner $$) & SPINNER_PID=$!

tasks_response=$(curl -s --location "$api_endpoint/todolists/$selected_id/tasks" \
--header "User-Agent: $user_agent" \
--header "x-api-key: $api_key")

kill $SPINNER_PID
wait $SPINNER_PID 2>/dev/null
echo ""

echo -e "$(tput bold)$(tput setaf 11) Select Proofhub Subtask"$(tput sgr0)

task_options=()
task_index=1
while read -r task_entry; do
    task_title=$(echo "$task_entry" | jq -r '.title')
    task_id=$(echo "$task_entry" | jq -r '.id')
    task_completed=$(echo "$task_entry" | jq -r '.completed')
    task_project_id=$(echo "$task_entry" | jq -r '.project.id')
    task_subtasks=$(echo "$task_entry" | jq -r '.sub_tasks')

    if [ "$task_completed" == "true" ]; then
        color=$(tput bold)$(tput setaf 2) 
    else
        color=$(tput bold)$(tput setaf 1)
    fi

    echo -e "${color}$task_index. $task_title" $(tput sgr0)

    task_options+=("$task_id")
    task_names+=("$task_title")
    task_subtask_counts+=("$task_subtasks")

    ((task_index++))
done < <(jq -c '.[] | {title: .title, id: .id, completed: .completed, project: .project, sub_tasks: .sub_tasks}' <<< "$tasks_response")



read -p "$(tput setaf 8)Enter the number of the task you want to select: $(tput sgr0)" selected_task_index

if [[ ! "$selected_task_index" =~ ^[1-9][0-9]*$ || "$selected_task_index" -gt "${#task_options[@]}" ]]; then
    echo "Invalid task selection. Please enter a valid number."
    exit 1
fi

selected_task_id="${task_options[selected_task_index - 1]}"
selected_task_subtasks="${task_subtask_counts[selected_task_index - 1]}"
echo "Selected Task:"$(tput bold)$(tput setaf 9) "${task_names[selected_task_index-1]}" $(tput sgr0)

echo ""

selected_subtask=""

if [ "$selected_task_subtasks" -gt 0 ]; then
    echo "Selected task has subtasks. Retrieving subtasks..."

    (spinner $$) & SPINNER_PID=$!

    subtasks_response=$(curl -s --location "$api_endpoint/todolists/$selected_id/tasks/${selected_task_id}/subtasks" \
    --header "User-Agent: $user_agent" \
    --header "x-api-key: $api_key")

    kill $SPINNER_PID
    wait $SPINNER_PID 2>/dev/null
    echo ""

    echo -e "$(tput bold)$(tput setaf 11) Select Proofhub Subtask$(tput sgr0)"

    subtask_options=()
    subtask_index=1
    while read -r subtask_entry; do
        subtask_title=$(echo "$subtask_entry" | jq -r '.title')
        subtask_id=$(echo "$subtask_entry" | jq -r '.id')
        subtask_completed=$(echo "$subtask_entry" | jq -r '.completed')

        if [ "$subtask_completed" == "true" ]; then
            color=$(tput bold)$(tput setaf 2)
        else
            color=$(tput bold)$(tput setaf 1)
        fi

        echo -e "${color}$subtask_index. $subtask_title" $(tput sgr0)

        subtask_options+=("$subtask_id")
        subtask_names+=("$subtask_title")
        ((subtask_index++))
    done < <(jq -c '.[]' <<< "$subtasks_response")

    read -p "$(tput setaf 8)Enter the number of the subtask you want to select: $(tput sgr0)" selected_subtask_index

if [[ -z "$selected_subtask_index" || ! "$selected_subtask_index" =~ ^[1-9][0-9]*$ || "$selected_subtask_index" -gt "${#subtask_options[@]}" ]]; then
    echo "Invalid subtask selection. Please enter a valid number."
    exit 1
fi

    selected_subtask_id="${subtask_options[selected_subtask_index - 1]}"
    selected_subtask_name="${subtask_names[selected_subtask_index - 1]}"

    echo "Selected Subtask:" $(tput bold)$(tput setaf 9) "$selected_subtask_name" $(tput sgr0)
selected_subtasks="${selected_subtask_id}"
else
    echo "Selected task does not have subtasks."
fi

echo ""

echo ""

echo -e "$(tput bold)$(tput setaf 11) Log Proofhub Time"$(tput sgr0)

read -p "Enter the description: " user_description
user_date=$(date +'%Y-%m-%d')

PS3="Select status (type the number and press Enter): "
options=("billable" "none")
select user_status in "${options[@]}"; do
    case $user_status in
        "billable"|"none")
            break
            ;;
        *)
            echo "Invalid option. Please select a valid status."
            ;;
    esac
done

read -p "Enter logged hours: " user_logged_hours
read -p "Enter logged minutes: " user_logged_mins

# POST time
url="$api_endpoint/timesheets/$selected_timesheet_id/time"

# Data to be posted
data_to_post='{
    "project": "'"$task_project_id"'",
    "timesheet_id": "'"$selected_timesheet_id"'",
    "date": "'"$user_date"'",
    "logged_hours": "'"$user_logged_hours"'",
    "logged_mins": "'"$user_logged_mins"'",
    "status": "'"$user_status"'",
    "description": "'"$user_description"'",
    "task_id": "'"$selected_task_id"'",
    "subtask_id": "'"$selected_subtask_id"'"
}'

    (spinner $$) & SPINNER_PID=$!

response=$(curl -s -X POST -H "$user_agent" -H "x-api-key: $api_key" -H "Content-Type: application/json" -d "$data_to_post" "$url")

    kill $SPINNER_PID
    wait $SPINNER_PID 2>/dev/null
    echo ""
# Check the response status
status=$(echo "$response" | jq -r '.status')
code=$(echo "$response" | jq -r '.code')
message=$(echo "$response" | jq -r '.message')


if [ -n "$status" ] && [ "$status" != "null" ]; then
	echo -e "$(tput bold)$(tput setaf 10) Finished!"$(tput sgr0)
  
else
    echo -e "$(tput bold)$(tput setaf 1) Error: $message"$(tput sgr0)
fi


