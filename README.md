# 🚀 DEP 9000

[![FTP](https://github.com/Black-HOST/deployer/actions/workflows/FTP.yml/badge.svg)](https://github.com/Black-HOST/deployer/actions/workflows/FTP.yml)
[![SFTP](https://github.com/Black-HOST/deployer/actions/workflows/SFTP.yml/badge.svg)](https://github.com/Black-HOST/deployer/actions/workflows/SFTP.yml)
[![RSYNC](https://github.com/Black-HOST/deployer/actions/workflows/RSYNC.yml/badge.svg)](https://github.com/Black-HOST/deployer/actions/workflows/RSYNC.yml)
[![SCRIPTS](https://github.com/Black-HOST/deployer/actions/workflows/SCRIPTS.yml/badge.svg)](https://github.com/Black-HOST/deployer/actions/workflows/SCRIPTS.yml)

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
          remote_dir: "/public_html"
```

For more advanced usage, see the [`.github/workflows/`](.github/workflows/) folder in this repository.

---

## 🦊 Quick start: GitLab CI

The same image is published on Docker Hub as [`blackhost/deployer`](https://hub.docker.com/r/blackhost/deployer), so a GitLab job needs nothing but the image and its variables:

```yaml
deploy:
  image: blackhost/deployer:1
  stage: deploy
  script: [deployer]
  variables:
    PROTOCOL: sftp
    SERVER: example.com
    REMOTE_DIR: public_html
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

Add `USERNAME` and `PASSWORD` (or `SSH_KEY`) as **masked** CI/CD variables in *Settings → CI/CD → Variables*. The job runs inside your checked-out repository, so `LOCAL_DIR` defaults to the project root.

Every key from the [Configuration](#️-configuration) table works as a variable, written in uppercase: `remote_dir` becomes `REMOTE_DIR`.

Two jobs for two targets is just two `variables:` blocks:

```yaml
deploy-api:
  extends: deploy
  variables: { SERVER: api.example.com, PASSWORD: $API_DEPLOY_PASS }
  rules: [{ if: $CI_COMMIT_BRANCH == "api" }]
```

Keep deploy settings inside the job. Project-wide variables with the same names (`PORT`, `DRY_RUN`, `DELETE`, `PARALLEL`) are picked up too.

---

## ⚙️ Configuration

| Key Name         | Required | Example                      | Default Value | Description                                                   |
|------------------|----------|------------------------------|---------------|---------------------------------------------------------------|
| protocol         | No       | `sftp`                       | `ftp`         | Connection protocol. Supports `ftp`, `sftp`, or `rsync`.    |
| server           | Yes      | `example.com`                | —             | Hostname or IP address of the deployment server.            |
| port             | No       | `22`                         | protocol default | Port for the chosen protocol (`21` for FTP, `22` for SFTP/rsync).|
| username         | Yes      | `deploy`                     | —             | Login username.                                             |
| password         | No       | `superSecretPassword`        | —             | Login password (FTP/SFTP only).                             |
| ssh_key  | No       | `<private-key>`              | —             | SSH private key for SFTP/SSH.                              |
| host_key         | No       | `ssh-ed25519 AAAA...`        | —             | Public SSH host key of the server (SFTP/rsync). When set, the deploy fails if the server presents any other key. |
| local_dir        | No       | `dist`                       | `.`           | Local directory to upload.                                  |
| remote_dir       | No       | `/public_html`               | `/`           | Remote directory on the server.                             |
| secure           | No       | `true`                       | `true`        | Use FTPS (FTP over TLS).                                    |
| verify_tls       | No       | `true`                       | `true`        | Verify SSL certificate for FTPS.                            |
| passive          | No       | `true`                       | `true`        | FTP passive mode.                                           |
| parallel         | No       | `2`                          | `2`           | Number of parallel file transfers.                          |
| delete           | No       | `true`                       | `false`       | Remove remote files not present locally (sync mode).         |
| only_newer       | No       | `true`                       | `false`       | Sync only files newer than remote files.                    |
| exclude          | No       | `.git/,node_modules,*.log`    | `.*,.*/,node_modules/,*.log`          | Comma-separated list of file/directory patterns to exclude. |
| include          | No       | `.htaccess,.well-known/`     | —             | Comma-separated list of file/directory patterns to deploy even when excluded, see [Dotfiles](#-dotfiles). |
| preserve_times   | No       | `true`                       | `false`       | Deploy files with their git commit times. Enables [delta uploads](#️-preserve-times--delta-uploads) for FTP/SFTP. |
| safeguards       | No       | `false`                      | `true`        | Refuse to deploy when `delete` is enabled and there is nothing to deploy, which would wipe the remote directory. |
| dry_run          | No       | `true`                       | `false`       | Run without making changes (test the deployment).           |
| pre_script       | No       | `echo Pre deploy`            | —             | Shell script to run before transfer.                        |
| post_script      | No       | `echo Post deploy`           | —             | Shell script to run after transfer.                         |
| remote_shell     | No       | `/bin/sh -c`                 | `/bin/bash -lc` | Shell used to run the pre/post scripts on the server.     |

---

## 🔒 Dotfiles

All dotfiles and dot-directories (`.env`, `.git/`, `.htaccess`, ...) are excluded by default. They often hold credentials or repository metadata that should never reach a web server.

To deploy one, list it in `include`. A directory needs a trailing slash:

```yaml
          include: ".htaccess,.well-known/"
```

An included file is synced like any other file: with `delete: true` it is also removed from the server when it does not exist in your local directory. Dotfiles that are not included are never uploaded and never deleted.

---

## ⏱️ Preserve times & delta uploads

A CI job starts from a fresh checkout, so every file carries the time of the checkout, not the time it was last changed. With `preserve_times: true` the deployer sets every file tracked by git to the time of its last commit before the transfer.

- **FTP / SFTP (delta uploads):** unchanged files have the same size and time as on the server, so only the files that changed are uploaded. Delta uploads are available only with `preserve_times` enabled; without it every deploy re-uploads all files.
- **rsync:** rsync sends only the changes either way. With `preserve_times` it also skips unchanged files without reading them.
- **All protocols:** the files on the server show the date of their last commit, not the date of the deploy.

The commit times come from the git history. CI checkouts are shallow by default, so the deployer fetches the missing history on its own (commits only, no file contents). Files that are not tracked by git, such as build output, keep their current time and are transferred as before. If the directory is not a git checkout, the option is skipped and the deploy runs as usual.

```yaml
      - uses: Black-HOST/deployer@v1
        with:
          protocol: sftp
          server: ${{ secrets.FTP_HOST }}
          username: ${{ secrets.FTP_USER }}
          password: ${{ secrets.FTP_PASS }}
          preserve_times: "true"
```

---

## 🏷️ Versioning

Every release is published under the same four references, as a GitHub Action and as a Docker image:

| GitHub Action                | Docker image                | Meaning                               |
|------------------------------|-----------------------------|---------------------------------------|
| `Black-HOST/deployer@v1.2.1` | `blackhost/deployer:1.2.1`  | exact release                         |
| `Black-HOST/deployer@v1.2`   | `blackhost/deployer:1.2`    | latest 1.2.x                          |
| `Black-HOST/deployer@v1`     | `blackhost/deployer:1`      | latest 1.x, recommended for pipelines |
| `Black-HOST/deployer@latest` | `blackhost/deployer:latest` | newest release                        |

`v1` receives every 1.x release, while `latest` also moves on to the next major version. Pin the exact release to decide for yourself when to update.

---

## ⚠️ Disclaimer
This software is provided "as is" without warranty of any kind, express or implied. While it has been tested extensively, you should use it at your own risk.

Be especially cautious when using the `delete: true` option, as it will permanently remove files from your remote server that do not exist in your local directory. If you don't feel confident, always perform a dry_run: true first to verify which files will be deleted.

---

## 📄 License

This project is maintained by [Black HOST Ltd.](https://black.host) and licensed under the MIT License.

See [`LICENSE`](LICENSE) file for more details.