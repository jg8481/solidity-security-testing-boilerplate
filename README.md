# Solidity Security Testing Tools For [Robot-Framework-Solidity-Testing-Toolkit](https://github.com/jg8481/Robot-Framework-Solidity-Testing-Toolkit)

This is a work-in-progress fork of patrickd's original "[solidity-fuzzing-boilerplate](https://github.com/patrickd-/solidity-fuzzing-boilerplate)" that is being re-designed to be used with the [Robot-Framework-Solidity-Testing-Toolkit](https://github.com/jg8481/Robot-Framework-Solidity-Testing-Toolkit). The new `run-solidity-security-tests.sh` included in this repo can also be used as a standalone security testing script, but it's designed to be used from a MacOS machine (could work on Linux too with minor changes). You can view a script help menu (without triggering any automation) by running `bash ./run-solidity-security-tests.sh -h` or `bash ./run-solidity-security-tests.sh --help`.

FYI Etheno has a known open issue with `pysha3` and it can be a blocker if you are usng Python 3.11, but you can work around it by using Python 3.10 ---> https://github.com/crytic/etheno/issues/122

```
src                    # Moved to "foundry" folder.
│
├── echidna.yaml       # Configuration file for Echidna.
├── foundry.toml       # Configuration file for Foundry.
├── build.sh           # Buildscript for downloading, compiling, initializing, ...
├── implementation     # Implementations to fuzz (downloaded by buildscript).
│   └── ...
├── expose             # Expose functions of libraries for tests.
│   └── ...
├── interface          # Interfaces for accessing exposers with incompatible Solidity versions.
│   └── ...
└── test               # Actual fuzzing testcases.
    ├── ...
    ├── addresses.sol  # Addresses of incompatible libs, generated by buildscript.
    └── helpers.sol    # Reusable helper functions for tests.
```

## Setup

Before any fuzzing can be run, `build.sh` needs to be executed, which has the following dependencies:

- bash
- curl
- [etheno](https://github.com/crytic/etheno)
- [foundry](https://book.getfoundry.sh/getting-started/installation.html)

After the buildscript was successfully executed, the implementation directory should be populated, there'll be a `echidna-init.json` file and a ganache instance will still be running in the background.

## Running Echidna Fuzzing

```bash
# Simple fuzzing with Echidna:
echidna-test --contract Test --config echidna.yaml src/test/example/BytesLib.sol

# Differential fuzzing against another implementation with incompatible Solidity version via initialization file:
echidna-test --contract Test --config echidna.yaml src/test/example/BytesLib-BytesUtil-diff.sol

# Differential fuzzing against an executable via FFI shell command execution:
echidna-test --contract Test --config echidna.yaml src/test/example/BytesLib-FFI-diff.sol
```

[*The FFI cheatcode is experimental in Echidna and only available when compiling with PR#750](https://github.com/crytic/echidna/pull/750)

## Running Foundry Fuzzing

```bash
# Simple fuzzing with Foundry:
forge test --match-test BytesLib_slice

# Differential fuzzing against another implementation with incompatible Solidity version via ganache fork:
forge test --fork-url http://127.0.0.1:8545/ --match-path src/test/example/BytesLib-BytesUtil-diff.sol

# Differential fuzzing against an executable via FFI shell command execution:
forge test --match-path src/test/example/BytesLib-FFI-diff.sol
```

Note that forge will appear to be stuck, but it's actually running 999999999 tests as configured in [foundry.toml](foundry.toml). This is intended to be kept running on servers for hours. If you instead want to run quick tests, eg. for CI, adjust the configuration according to your needs.

## Reproducing a finding / Manual testing

```bash
# Call function of exposed library and show execution trace:
forge run --sig "slice(bytes,uint256,uint256)" --target-contract ExposedBytesLib -vvvv src/expose/example/BytesLib.sol 0x010203 1 1

# Manually execute a testcase to reproduce an issue:
forge run --fork-url http://127.0.0.1:8545/ --sig "test_BytesLib_BytesUtil_diff_slice(bytes,uint256,uint256)" --target-contract Test -vvvv src/test/example/BytesLib-BytesUtil-diff.sol 0x010203 1 1
```

##### ✂ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - SNIP - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# Solidity Fuzzing Boilerplate

This is a template repository intended to ease fuzzing components of Solidity projects, especially libraries.

- Write tests once and run them with both [Echidna](https://github.com/crytic/echidna) and [Foundry](https://book.getfoundry.sh/forge/fuzz-testing.html)'s fuzzing.
- Fuzz components that use incompatible Solidity versions by deploying those into a Ganache instance via Etheno.
- Use HEVM's FFI cheatcode to generate complex fuzzing inputs or to compare outputs with non-EVM executables while doing differential fuzzing.
- Publish your fuzzing experiments without worrying about licensing by extending the shellscript to download specific files.

## How to use the Template

### 1. Check & adjust configs

Check the [echidna.yaml](echidna.yaml) and [foundry.toml](foundry.toml) configuration files.

- Turn off FFI if you don't intend to make use of shell commands from your Solidity contracts. Note that FFI is slow and should only be used as a workaround. It can be useful for testing against things that are difficult to implement within Solidity and already exist in other languages. But it can also be dangerous: Before executing tests of a project that has FFI enabled, be sure to check what commands are actually being executed. There's nothing stopping someone to write a malicious testcase and execute malware on your computer.
- Adjust the compiler optimization options to match those of the project you're fuzzing.
- The default number of test runs configured, assumes that you intend to leave these tests running for a while to find edge cases, eg. on servers. Reduce the numbers accordingly if you only want to run quick tests.
- Adjust things like sequence lengths when fuzzing contracts that have a state (where a previous transaction can impact the next one).

### 2. Adjust Buildscript

Edit the [build.sh](build.sh) file and adjust it for your usecase

- Fetch the implementations that you want to apply fuzzing on.
- During RECORDing, deploy contracts of incompatible Solidity versions in order to access them during tests.
- If you're not dealing with any contracts of incompatible versions, you can simply omit the RECORD and DEPLOY calls.

### 3. Create testcases and exposers/interfaces as needed

Take a look at the [example testcases](src/test/example) and write your own.

### 4. Adjust the README.md

Don't forget to document the intention, setup and commands for your fuzzing campaign.
