#!/bin/bash

# Copyright 2023 The Reg Reporting Blueprint Authors

# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at

#     https://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

SETTINGS_FILE="$1"
if [ "${SETTINGS_FILE}" == "" ]; then
  echo "Specify the settings file to initialise"
fi
if [ -f "${SETTINGS_FILE}" ]; then
  echo "The settings file already exists. Exiting..."
  exit 0
fi

# Create the settings file directory
mkdir -p "$(dirname ${SETTINGS_FILE})"

# Create the settings file
cat > "${SETTINGS_FILE}" <<EOF
{
  // This is for convenience.
  //
  // If opening the DBT file directly, do not prompt
  // to open the parent Git folder.
  "git.openRepositoryInParentFolders": "never",

  // Example SQLfluff configuration
  "[sql]": {
    "editor.defaultFormatter": "RobertOstermann.vscode-sqlfluff"
  },
  "sqlfluff.dialect": "bigquery",
  "sqlfluff.linter.run": "onSave",
  "sqlfluff.experimental.format.executeInTerminal": true,
  "editor.formatOnSave": false,
  "sqlfluff.format.enabled": true,
  "sqlfluff.executablePath": "$HOME/.local/bin/sqlfluff"
}
EOF
