# 🚀 DEP 9000

[![FTP](https://github.com/Black-HOST/deployer/actions/workflows/ftps-deploy.yml/badge.svg)](https://github.com/Black-HOST/deployer/actions/workflows/ftps-deploy.yml)

Deployer 9000 is a lightweight, CI/CD-ready deployment tool for GitHub Actions and other automation environments. Deploy your code via FTP, FTPS, SFTP, or SSH with simple configuration and secure best practices.

---

## ✨ Features

- 🚦 **Deploys always:** You won't see messages like "I'm sorry, Dave, I'm afraid I can't let you deploy that..." - Unlike his cousin HAL, DEP 9000 gets the job done!
- 🔌 **Protocol Support:** FTP, FTPS (with TLS), SFTP, SSH (rsync)
- 🤖 **CI/CD Ready:** Designed for seamless integration with GitHub Actions
- 🛡️ **Secure by Default:** Enforces SSL/TLS verification, supports SSH keys
- ⚙️ **Highly Configurable:** Control transfer options, parallel uploads, excludes, dry runs, pre/post scripts
- 📦 **Minimal Dependencies:** Alpine-based Docker image, single binary deployer

---

## 🏁 GitHub Actions: Setup & Usage

### 1️⃣ Add Secrets

Go to your repository’s **Settings > Secrets and variables > Actions** and add at least:

- `FTP_HOST` — The FTP/SFTP/SSH server host or IP.
- `FTP_USER` — Login username.
- `FTP_PASS` — Login password (for FTP/SFTP) or leave empty if using SSH keys.

### 2️⃣ Create Workflow File

Add (or update) `.github/workflows/deploy.yml` in your repository with a minimal deploy step:

```yaml
name: Deploy

on:
  push:
    branches: [ "main" ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Code Deployment
        uses: Black-HOST/deployer@v1
        with:
          server: ${{ secrets.FTP_HOST }}
          username: ${{ secrets.FTP_USER }}
          password: ${{ secrets.FTP_PASS }}
          remote-dir: "/public_html"
```

For more advanced usage, see the [`.github/workflows/`](.github/workflows/) folder in this repository.

---

## ⚙️ Configuration

| Key Name         | Required | Example                      | Default Value | Description                                                   |
|------------------|----------|------------------------------|---------------|---------------------------------------------------------------|
| protocol         | No       | `sftp`                       | `ftp`         | Connection protocol. Supports `ftp`, `sftp`, or `ssh`.      |
| server           | Yes      | `example.com`                | —             | Hostname or IP address of the deployment server.            |
| port             | No       | `22`                         | protocol default | Port for the chosen protocol (`21` for FTP, `22` for SFTP/SSH).|
| username         | Yes      | `deploy`                     | —             | Login username.                                             |
| password         | No       | `superSecretPassword`        | —             | Login password (FTP/SFTP only).                             |
| ssh-private-key  | No       | `<private-key>`              | —             | SSH private key for SFTP/SSH.                              |
| local-dir        | No       | `dist`                       | `.`           | Local directory to upload.                                  |
| remote-dir       | No       | `/public_html`               | `/`           | Remote directory on the server.                             |
| secure           | No       | `true`                       | `true`        | Use FTPS (FTP over TLS).                                    |
| verify-tls       | No       | `true`                       | `true`        | Verify SSL certificate for FTPS.                            |
| passive          | No       | `true`                       | `true`        | FTP passive mode.                                           |
| parallel         | No       | `2`                          | `2`           | Number of parallel file transfers.                          |
| delete           | No       | `true`                       | `false`       | Remove remote files not present locally (sync mode).         |
| only-newer       | No       | `true`                       | `true`        | Sync only files newer than remote files.                    |
| exclude          | No       | `.git,node_modules,*.log`    | `.git,node_modules,*.log`             | Comma-separated list of file/directory patterns to exclude. |
| dry-run          | No       | `true`                       | `false`       | Run without making changes (test the deployment).           |
| pre-script       | No       | `echo Pre deploy`            | —             | Shell script to run before transfer.                        |
| post-script      | No       | `echo Post deploy`           | —             | Shell script to run after transfer.                         |

---

## 📄 License

This project is maintained by [Black HOST Ltd.](https://github.com/Black-HOST).

See LICENSE file for details.