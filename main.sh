#!/usr/bin/env bash

set -eo pipefail

installation_script="$(mktemp)"
curl -sSL https://install.python-poetry.org/ --output "$installation_script"

if [ "${RUNNER_OS}" == "Windows" ]; then
  path="C:/Users/runneradmin/AppData/Roaming/Python/Scripts"
else
  path="$HOME/.local"
fi

echo -e "\n\033[33mSetting Poetry installation path as $path\033[0m\n"
echo -e "\033[33mInstalling Poetry 👷\033[0m\n"

echo "ECHO 0"

if [ "${VERSION}" == "latest" ]; then
  # Note: If we quote installation arguments, the call below fails
  # shellcheck disable=SC2086
  POETRY_HOME=$path python3 ${installation_script} --yes ${INSTALLATION_ARGUMENTS}
else
  # shellcheck disable=SC2086
  POETRY_HOME=$path python3 ${installation_script} --yes --version=${VERSION} ${INSTALLATION_ARGUMENTS}
fi

echo "ECHO 0.1"

echo "$path/bin" >>"$GITHUB_PATH"
export PATH="$path/bin:$PATH"

echo "ECHO 0.2"

if [ "${RUNNER_OS}" == "Windows" ]; then
  poetry_="$path/bin/poetry.exe"
else
  poetry_=poetry
fi


echo "ECHO 0.3"
$poetry_

echo "ECHO 0.4"

# Expand any "~" in VIRTUALENVS_PATH
VIRTUALENVS_PATH="${VIRTUALENVS_PATH/#\~/$HOME}"

echo "ECHO 1"

$poetry_ config experimental.new-installer false

echo "ECHO 2"

$poetry_ config virtualenvs.create ${VIRTUALENVS_CREATE}

echo "ECHO 3"

$poetry_ config virtualenvs.in-project ${VIRTUALENVS_IN_PROJECT}

echo "ECHO 4"

$poetry_ config virtualenvs.path ${VIRTUALENVS_PATH}

echo "ECHO 5"

config="$($poetry_ config --list)"

if echo "$config" | grep -q -c "installer.parallel"; then
  $poetry_ config installer.parallel ${INSTALLER_PARALLEL}
fi

echo "ECHO 6"

if [ "${RUNNER_OS}" == "Windows" ]; then
  act="source .venv/scripts/activate"
  echo "VENV=.venv/scripts/activate" >>"$GITHUB_ENV"
else
  act="source .venv/bin/activate"
  echo "VENV=.venv/bin/activate" >>"$GITHUB_ENV"
fi

echo -e "\n\033[33mInstallation completed. Configuring settings 🛠\033[0m"
echo -e "\n\033[33mDone ✅\033[0m"

if [ "${VIRTUALENVS_CREATE}" == true ] || [ "${VIRTUALENVS_CREATE}" == "true" ]; then
  echo -e "\n\033[33mIf you are creating a venv in your project, you can activate it by running '$act'. If you're running this in an OS matrix, you can use 'source \$VENV' instead, as an OS agnostic option\033[0m"
fi
if [ "${RUNNER_OS}" == "Windows" ]; then
  echo -e "\n\033[33mMake sure to set your default shell to bash when on Windows.\033[0m"
  echo -e "\n\033[33mSee the github action docs for more information and examples.\033[0m"
fi
