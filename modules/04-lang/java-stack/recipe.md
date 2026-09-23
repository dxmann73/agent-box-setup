# java-stack recipe

Run after `kubuntu-baseline` on the catalog-ticked agent VM only. The Dave overlay defines the Java
21 Oracle candidate, SDKMAN auto-env setting, Quarkus analytics file, and the SDKMAN-managed Maven
and Quarkus CLIs.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/04-lang/java-stack
sudo ./apply.sh --target agent-vm
```

Apply installs SDKMAN prerequisites, then installs the overlay's Java `21.0.12-oracle` candidate,
Quarkus, and Maven as the invoking desktop user. It never writes credentials.

## Verify

```bash
./verify.sh --target agent-vm
```

Run the verifier as the normal desktop user so it can load that user's SDKMAN environment.
