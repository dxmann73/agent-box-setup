# libreoffice recipe

Run on a catalog-ticked daily host. LibreOffice provides local document editing; web-based office
work may remain in the personal browser guest when selected by the deployment.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/07-apps/libreoffice
sudo ./apply.sh
```

The script installs Ubuntu's `libreoffice` metapackage. Open representative real-world office files
after installation to confirm their required formatting and compatibility.

## Verify

```bash
./verify.sh
```

The verifier checks the package and command availability. It does not open or alter documents.
