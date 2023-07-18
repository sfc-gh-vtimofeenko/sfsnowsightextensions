This is a Nix flake that configures sfsnowsightextensions. Currently only works on Linux.

# How to use

## Powershell environment

To get into a Powershell environment:

```shell
SNOWFLAKE_ACCOUNT="<ACCOUNT_NAME>" SNOWFLAKE_USER="<USER_NAME>" SNOWFLAKE_PASSWORD="<PASSWORD>" nix run .#sfsnowsightextensions-launch
```

This will open Powershell prompt with authentication stored in `$app`.

## Create worksheet

To create a sample worksheet from a file included in this repo:

```shell
SNOWFLAKE_ACCOUNT="<ACCOUNT_NAME>" SNOWFLAKE_USER="<USER_NAME>" SNOWFLAKE_PASSWORD="<PASSWORD>" nix run .#ssample-create-worksheet
```
