---

# Proofhub Project Initialization Script

## Overview

This Bash script is designed to initialize a Proofhub project by creating a `proofhub.json` configuration file. It prompts the user to enter Proofhub login details (email and API key) and then allows the user to select a Proofhub project. The selected project's ID, along with the user's login details, is then stored in the `proofhub.json` file for future use.

## Dependencies

Ensure that the following dependencies are installed on your system:

- `jq` (JSON processor): [jq Installation Guide](https://stedolan.github.io/jq/download/)
- `curl`: [curl Download Page](https://curl.haxx.se/download.html)

Replace the placeholder values with your Proofhub API details.

## Requirements

- Bash
- jq (JSON processor)
- Proofhub account
- Proofhub API key

## Usage

1. Ensure that `jq` and `fzf` are installed on your system.

   ```bash
   sudo apt-get install jq fzf   # Use the appropriate package manager for your system
   ```

2. Make the script executable:

   ```bash
   chmod +x proofhub_init.sh
   ```

3. Run the script:

   ```bash
   ./proofhub_init.sh
   ```

4. Enter your Proofhub email and API key when prompted.

5. The script will fetch a list of Proofhub projects and display them with corresponding indices.

6. Enter the number corresponding to the desired project.

7. The script will create a `proofhub.json` file with the selected project's information.

### Example `proofhub.json`:

```json
{
  "API_ENDPOINT": "https://example.proofhub.com/api/v3",
  "USER_AGENT": "your_proofhub_email@example.com",
  "API_KEY": "your_proofhub_api_key"
}
```

## Notes

- Ensure that `jq` is installed on your system.
- Provide your Proofhub email and API key when prompted.
- Select the Proofhub project by entering the corresponding number.
- The script will create a `proofhub.json` file with the selected project's information.

---

# Proofhub Time Logging Script

## Overview

This Bash script facilitates time logging in Proofhub by interacting with the Proofhub API. It allows users to select a Proofhub Timesheet, Todolist, Task, and Subtask, and logs time for the selected entry.

## Requirements

- Bash
- jq (JSON processor)
- `curl`
- `proofhub.json`

## Usage

1. **Run the Script:**

    ```bash
    chmod +x phtimelog.sh
    ./phtimelog.sh
    ```

2. **Follow the prompts:**

    - Select a Proofhub Timesheet.
    - Choose a Todolist.
    - Pick a Task.
    - If the Task has subtasks, select a Subtask.
    - Enter time details when prompted.

3. **Review Results:**

    - The script will display the selected entries and log the time in Proofhub.

## Notes

- Ensure you have the necessary permissions in Proofhub to log time.
- Review the script prompts and provide accurate information.

---
