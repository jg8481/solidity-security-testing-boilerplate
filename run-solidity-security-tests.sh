#!/bin/bash

# This "run-solidity-security-tests.sh" Bash tool runner script is a modified version of patrickd's original "build.sh" found in his "solidity-fuzzing-boilerplate".

TIMESTAMP=$(date)
clear

FETCH () {
    local DESTINATION=$1
    local SOURCE=$2
    echo "# Fetching implementation 'DESTINATION'..."
    local DESTINATION_DIR=$(dirname "$DESTINATION")
    mkdir -p "$DESTINATION_DIR"
    curl $SOURCE > "$DESTINATION"
}
BUILD () {
    echo "# Compiling contracts..."
    $HOME/.foundry/bin/forge build
}
RECORD_START () {
    # Create a file containing all of these contract's addresses as constants
    echo "// SPDX-License-Identifier: MIT" > /tmp/addresses.sol.tmp
    echo "// Automatically generated by run-solidity-security-tests.sh" >> /tmp/addresses.sol.tmp
    echo "pragma solidity >=0.5.0;" >> /tmp/addresses.sol.tmp
    # Record all transactions made with etheno in the background
    etheno --ganache --ganache-args "--deterministic --gasLimit 10000000" -x /tmp/echidna-init.json &
    ETHENO_PID=$!
    sleep 5
}
DEPLOY () {
    local FILE=$1
    local CONTRACT=$2
    local GANACHE_KEY="0xf2f48ee19680706196e2e339e5da3491186e0c4c5030670656b0e0164837257d"
    local ETHENO_URL="http://127.0.0.1:8545/"
    echo "# Deploying '$CONTRACT' to etheno..."
    # Use foundry to deploy contracts via etheno
    CONTRACT_ADDRESS=$($HOME/.foundry/bin/forge create --legacy --rpc-url "$ETHENO_URL" --private-key $GANACHE_KEY "$FILE:$CONTRACT" | grep "Deployed to")
    CONTRACT_ADDRESS=${CONTRACT_ADDRESS#Deployed to: 0x}
    echo "address constant $CONTRACT = address(0x00$CONTRACT_ADDRESS);" >> /tmp/addresses.sol.tmp # we don't get addresses with valid checksums from forge, workaround with 00 prefix
}
RECORD_END () {
    # Finish address constants file
    rm ./foundry/src/test/addresses.sol
    mv /tmp/addresses.sol.tmp ./foundry/src/test/addresses.sol
    $HOME/.foundry/bin/forge build
    echo "# Creating initialization file for Echidna..."
    cp /tmp/echidna-init.json echidna-init.json
    echo "]" >> echidna-init.json # ensure JSON array ends validly
    # JSON from etheno has some values as numbers but Echidna expects all of them to be a string
    sed -i 's/"\([^"]\{1,32\}\)": \([0-9]\{1,32\}\)/"\1": "\2"/g' echidna-init.json
    echo "# WARNING: Keeping etheno/ganache instance running in the background for Forge fuzzing!"
    echo "# Stop it with 'kill -s SIGTERM $ETHENO_PID' when you're done!"
}

if [ "$1" == "Install-Solidity-Security-Testing-Tools-On-MacOS" ]; then
  echo
  echo "------------------------------------[[[[ Install-Solidity-Security-Testing-Tools-On-MacOS ]]]]------------------------------------"
  echo
  echo "This command will install all of the required tools for Solidity fuzz testing using this tool runner script. This run started on $TIMESTAMP."
  echo
  rm -rf ./foundry/src/implementation/
  rm -rf ./foundry/lib/forge-std
  rm -rf ./foundry/lib/openzeppelin-contracts
  rm -rf ./echidna/openzeppelin-contracts
  git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git ./foundry/lib/openzeppelin-contracts
  git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git ./echidna/openzeppelin-contracts
  git clone https://github.com/foundry-rs/forge-std.git ./foundry/lib/forge-std
  rm -rf ../foundry/lib/forge-std/lib/ds-test
  git clone https://github.com/dapphub/ds-test.git ./foundry/lib/forge-std/lib/ds-test
  npm -g i ganache
  brew install python@3.9
  brew install python@3.10
  brew install git
  brew install libusb && curl -L https://foundry.paradigm.xyz | bash && source $HOME/.bashrc && foundryup
  pip3.9 install virtualenv
  pip3.10 install --user pysha3
  pip3.10 install --user etheno
  pip install mythx-cli
  pip3.9 install mythril
  source $HOME/.bashrc
  $HOME/.foundry/bin/forge -h
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit 0
fi

if [ "$1" == "Stop-Containers-And-Build-Docker-Container-With-Compose" ]; then
  # source ./.env
  echo
  echo "------------------------------------[[[[ Stop-Containers-And-Build-Docker-Container-With-Compose ]]]]------------------------------------"
  echo
  echo "This will build the Docker image defined in the docker-compose.yml file. This run started on $TIMESTAMP."
  echo
  docker stop $(docker ps -a -q) &&
  docker rm $(docker ps -a -q)
  docker compose -f docker-compose.yml down
  docker compose -f docker-compose.yml rm -f
  docker compose -f docker-compose.yml build
  TIMESTAMP2=$(date)
  echo "This build ended on $TIMESTAMP2."
fi

if [ "$1" == "Stop-Containers-And-Setup-New-ConsenSys-Mythril-Docker-Container" ]; then
  echo
  echo "------------------------------------[[[[ Stop-Containers-And-Setup-New-ConsenSys-Mythril-Docker-Container ]]]]------------------------------------"
  echo
  echo "This command requires Docker to be installed first and is meant to be used with the Run-ConsenSys-Mythril-In-Docker-For-Vulnerability-Scanner-Tests command. This run started on $TIMESTAMP."
  echo
  docker stop $(docker ps -a -q) &&
  docker rm $(docker ps -a -q)
  docker pull mythril/myth
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit 0
fi

if [ "$1" == "Fetch-For-Fuzz-Test" ]; then
  clear
  echo
  echo "------------------------------------[[[[ Fetch-For-Fuzz-Test ]]]]------------------------------------"
  echo
  echo "This command will get Solidity Smart Contract files to fuzz test and compile them using Foundry. This run started on $TIMESTAMP."
  echo
  # Fetch implementations to fuzz
  # Original code from build.sh is below...
  #FETCH ./foundry/src/implementation/example/BytesLib.sol "https://raw.githubusercontent.com/GNSPS/solidity-bytes-utils/master/contracts/BytesLib.sol"
  #FETCH ./foundry/src/implementation/example/BytesUtil.sol "https://raw.githubusercontent.com/libertylocked/solidity-bytesutil/master/contracts/BytesUtil.sol"
  FETCH $2 $3
  ls -la ./foundry/src/implementation/example
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit
fi

if [ "$1" == "Compile-For-Foundry-Fuzz-Test" ]; then
  clear
  echo
  echo "------------------------------------[[[[ Compile-For-Foundry-Fuzz-Test ]]]]------------------------------------"
  echo
  echo "This command will get Solidity Smart Contract files to fuzz test and compile them using Foundry. This run started on $TIMESTAMP."
  echo
  # Compile contracts
  BUILD
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit
fi

if [ "$1" == "Deploy-For-Fuzz-Test" ]; then
  clear
  echo
  echo "------------------------------------[[[[ Deploy-For-Fuzz-Test ]]]]------------------------------------"
  echo
  echo "This command will deploy Solidity Smart Contract files to fuzz test and record them using Etheno. This run started on $TIMESTAMP."
  echo
  # Original code from build.sh is below...
  #DEPLOY ./foundry/src/expose/example/BytesLib.sol ExposedBytesLib
  #DEPLOY ./foundry/src/expose/example/BytesUtil.sol ExposedBytesUtil
  DEPLOY $2 $3
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit
fi

if [ "$1" == "Record-Start-For-Fuzz-Test" ]; then
  clear
  echo
  echo "------------------------------------[[[[ Record-Start-For-Fuzz-Test ]]]]------------------------------------"
  echo
  echo "This command will start recording the Smart Contract deployments using Etheno. This run started on $TIMESTAMP."
  echo
  RECORD_START
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit
fi

if [ "$1" == "Record-End-For-Fuzz-Test" ]; then
  clear
  echo
  echo "------------------------------------[[[[ Record-End-For-Fuzz-Test ]]]]------------------------------------"
  echo
  echo "This command will stop the Smart Contract deployment recording using Etheno. This run started on $TIMESTAMP."
  echo
  RECORD_END
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit
fi

if [ "$1" == "Setup-Foundry-And-Run-Fuzz-Specific-Test" ]; then
  clear
  echo
  echo "------------------------------------[[[[ Setup-Foundry-And-Run-Fuzz-Specific-Test ]]]]------------------------------------"
  echo
  echo "This command will setup just Foundry for Solidity Smart Contract fuzz testing. This run started on $TIMESTAMP."
  echo
  rm -rf ./foundry/src/implementation/
  rm -rf ./foundry/lib/forge-std
  rm -rf ./foundry/lib/openzeppelin-contracts
  git clone https://github.com/foundry-rs/forge-std.git ./foundry/lib/forge-std
  rm -rf ./foundry/lib/forge-std/lib/ds-test
  git clone https://github.com/dapphub/ds-test.git ./foundry/lib/forge-std/lib/ds-test
  brew install libusb && curl -L https://foundry.paradigm.xyz | bash && source $HOME/.bashrc && foundryup
  source $HOME/.bashrc
  echo
  echo "The 'foundryup' command has completed. The following 'forge' version has been installed:"
  $HOME/.foundry/bin/forge --version
  echo
  # Fetch implementations to fuzz. Feel free to change the following 'FETCH' targets to anything you want.
  FETCH ./foundry/src/implementation/example/BytesLib.sol "https://raw.githubusercontent.com/GNSPS/solidity-bytes-utils/master/contracts/BytesLib.sol"
  FETCH ./foundry/src/implementation/example/BytesUtil.sol "https://raw.githubusercontent.com/libertylocked/solidity-bytesutil/master/contracts/BytesUtil.sol"
  FETCH ./foundry/src/implementation/Sender.sol "https://raw.githubusercontent.com/jg8481/foundry-fuzzer/main/src/Sender.sol"
  FETCH ./foundry/src/implementation/Greeting.sol "https://raw.githubusercontent.com/jg8481/foundry-cheatsheet/main/Greeting.sol"
  # Compile contracts
  BUILD > /dev/null 2>&1
  # Run Foundry's 'forge' command to target a specific test by name
  $HOME/.foundry/bin/forge test --match-test "$2"
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit
fi

if [ "$1" == "Setup-Foundry-And-Run-All-Fuzz-Tests" ]; then
  clear
  echo
  echo "------------------------------------[[[[ Setup-Foundry-And-Run-All-Fuzz-Tests ]]]]------------------------------------"
  echo
  echo "This command will setup just Foundry for Solidity Smart Contract fuzz testing. This run started on $TIMESTAMP."
  echo
  rm -rf ./foundry/src/implementation/
  rm -rf ./foundry/lib/forge-std
  rm -rf ./foundry/lib/openzeppelin-contracts
  git clone https://github.com/foundry-rs/forge-std.git ./foundry/lib/forge-std
  rm -rf ./foundry/lib/forge-std/lib/ds-test
  git clone https://github.com/dapphub/ds-test.git ./foundry/lib/forge-std/lib/ds-test
  brew install libusb && curl -L https://foundry.paradigm.xyz | bash && source $HOME/.bashrc && foundryup
  source $HOME/.bashrc
  echo
  echo "The 'foundryup' command has completed. The following 'forge' version has been installed:"
  $HOME/.foundry/bin/forge --version
  echo
  # Fetch implementations to fuzz. Feel free to change the following 'FETCH' targets to anything you want.
  FETCH ./foundry/src/implementation/example/BytesLib.sol "https://raw.githubusercontent.com/GNSPS/solidity-bytes-utils/master/contracts/BytesLib.sol"
  FETCH ./foundry/src/implementation/example/BytesUtil.sol "https://raw.githubusercontent.com/libertylocked/solidity-bytesutil/master/contracts/BytesUtil.sol"
  FETCH ./foundry/src/implementation/Sender.sol "https://raw.githubusercontent.com/jg8481/foundry-fuzzer/main/src/Sender.sol"
  FETCH ./foundry/src/implementation/Greeting.sol "https://raw.githubusercontent.com/jg8481/foundry-cheatsheet/main/Greeting.sol"
  # Compile contracts
  BUILD > /dev/null 2>&1
  # Run Foundry's 'forge' command to target a specific test by name
  $HOME/.foundry/bin/forge test 
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit
fi

if [ "$1" == "Setup-Echidna-Exploration-Mode-And-Run-Fuzz-Test" ]; then
  clear
  echo
  echo "------------------------------------[[[[ Setup-Echidna-Exploration-Mode-And-Run-Fuzz-Test ]]]]------------------------------------"
  echo
  echo "This command will setup just Echidna for Solidity Smart Contract fuzz testing. This run started on $TIMESTAMP."
  echo
  rm -rf ./echidna/openzeppelin-contracts
  git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git ./echidna/openzeppelin-contracts
  brew install echidna
  echo
  # Run Echidna command in exploratory mode targeting a specific file
  echidna ./echidna/"$2" --test-mode exploration
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit
fi

if [ "$1" == "Setup-ConsenSys-Mythril-And-Run-Vulnerability-Scanner-Tests" ]; then
  clear
  echo
  echo "------------------------------------[[[[ Setup-ConsenSys-Mythril-And-Run-Vulnerability-Scanner-Tests ]]]]------------------------------------"
  echo
  echo "This command will setup just Mythril for Solidity Smart Contract scanning. This run started on $TIMESTAMP."
  echo
  rm -rf ./mythril/openzeppelin-contracts
  git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git ./mythril/openzeppelin-contracts
  pip3.9 install virtualenv
  virtualenv venv --python=python3.9
  source venv/bin/activate
  pip3.9 install mythril
  myth analyze "$2"
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit
fi

if [ "$1" == "Run-ConsenSys-Mythril-In-Docker-For-Vulnerability-Scanner-Tests" ]; then
  clear
  echo
  echo "------------------------------------[[[[ Run-ConsenSys-Mythril-In-Docker-For-Vulnerability-Scanner-Tests ]]]]------------------------------------"
  echo
  echo "This command requires Docker to be installed first and will run only Mythril for Solidity Smart Contract scanning. This run started on $TIMESTAMP."
  echo
  rm -rf ./echidna/openzeppelin-contracts
  git clone https://github.com/OpenZeppelin/openzeppelin-contracts.git ./mythril/openzeppelin-contracts
  docker run -v $(pwd):/tmp mythril/myth analyze "$2" -o markdown
  TIMESTAMP2=$(date)
  echo "This run ended on $TIMESTAMP2."
  exit
fi

usage_explanation() {
  echo
  echo
  echo "------------------------------------[[[[ Tool Runner Script ]]]]------------------------------------"
  echo
  echo
  echo "This tool runner script can be used to run the following commands. You can view just this help menu again (without triggering any automation) by running 'bash ./run-solidity-security-tests.sh -h' or 'bash ./run-solidity-security-tests.sh --help'." 
  echo 
  echo "---->>>> Option 1: Setup Etheno And Foundry Fuzz Tests With Specific Commands <<<<----"
  echo "If you want to specifically control how these Solidity fuzz tests will run while using Etheno and Foundry, please follow the order of ALL the individual 'bash' commands below. Starting with 'Install-Solidity-Security-Testing-Tools-On-MacOS', then all of the 'Fetch-For-Fuzz-Test' commands, and ending with the 'Record-End-For-Fuzz-Test' command."
  echo
  echo
  echo "bash ./run-solidity-security-tests.sh Install-Solidity-Security-Testing-Tools-On-MacOS"
  echo "bash ./run-solidity-security-tests.sh Stop-Containers-And-Build-Docker-Container-With-Compose"
  echo "bash ./run-solidity-security-tests.sh Fetch-For-Fuzz-Test ./foundry/src/implementation/example/BytesUtil.sol 'https://raw.githubusercontent.com/jg8481/solidity-bytesutil/master/contracts/BytesUtil.sol'"
  echo "bash ./run-solidity-security-tests.sh Fetch-For-Fuzz-Test ./foundry/src/implementation/example/BytesLib.sol 'https://raw.githubusercontent.com/jg8481/solidity-bytes-utils/master/contracts/BytesLib.sol'"
  echo "bash ./run-solidity-security-tests.sh Compile-For-Foundry-Fuzz-Test"
  echo "bash ./run-solidity-security-tests.sh Record-Start-For-Fuzz-Test"
  echo "bash ./run-solidity-security-tests.sh Deploy-For-Fuzz-Test ./foundry/src/expose/example/BytesLib.sol ExposedBytesLib"
  echo "bash ./run-solidity-security-tests.sh Deploy-For-Fuzz-Test ./foundry/src/expose/example/BytesUtil.sol ExposedBytesUtil"
  echo "bash ./run-solidity-security-tests.sh Record-End-For-Fuzz-Test"
  echo
  echo
  echo "---->>>> Option 2: Run All Test Setups And Focus On Foundry Or Echidna Fuzz Tests <<<<----"
  echo "If you want to run only Foundry or Echidna fuzz tests, please run only the 'Setup-Foundry-...' or 'Setup-Echidna-...' commands below."
  echo
  echo
  echo "bash ./run-solidity-security-tests.sh Setup-Foundry-And-Run-Fuzz-Specific-Test BytesLib_BytesUtil_diff_slice"
  echo "bash ./run-solidity-security-tests.sh Setup-Foundry-And-Run-Fuzz-Specific-Test test_Fuzz_Sender"
  echo "bash ./run-solidity-security-tests.sh Setup-Foundry-And-Run-Fuzz-Specific-Test Greeting"
  echo "bash ./run-solidity-security-tests.sh Setup-Foundry-And-Run-All-Fuzz-Tests"
  echo "bash ./run-solidity-security-tests.sh Setup-Echidna-Exploration-Mode-And-Run-Fuzz-Test token.sol"
  echo
  echo
  echo "---->>>> Option 3: Run All Test Setups And Focus On Security Vulnerability Tests  <<<<----"
  echo "If you want to run only the Solidity vulnerability scanning tools, please run only the 'Setup-ConsenSys-Mythril-...' commands below."
  echo
  echo
  echo "bash ./run-solidity-security-tests.sh Setup-ConsenSys-Mythril-And-Run-Vulnerability-Scanner-Tests <replace_this_with_the_path_to_your_Solidity_source_code_file_on_your_host_machine>"
  echo "bash ./run-solidity-security-tests.sh Stop-Containers-And-Setup-New-ConsenSys-Mythril-Docker-Container"
  echo "bash ./run-solidity-security-tests.sh Run-ConsenSys-Mythril-In-Docker-For-Vulnerability-Scanner-Tests <replace_this_with_the_path_to_your_Solidity_source_code_file_on_your_Docker_container>"
  echo
  echo
}

error_handler() {
  local error_message="$@"
  echo "${error_message}" 1>&2;
}

argument="$1"
if [[ -z $argument ]] ; then
  usage_explanation
else
  case $argument in
    -h|--help)
      usage_explanation
      ;;
    *)
      usage_explanation
      ;;
  esac
fi