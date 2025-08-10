FROM alpine:3.20

# install dependencies lftp for FTP/SFTP, openssh-client + rsync for SSH deploy & scripts
RUN apk add --no-cache \
	lftp ca-certificates bash coreutils findutils grep sed \
	openssh-client rsync sshpass\
	&& update-ca-certificates

# create the .ssh dir
RUN mkdir /root/.ssh

# set the deployer working dir
WORKDIR /app

# install the deployer binaries
COPY deployer /usr/bin/deployer
COPY lib /usr/share/deployer
RUN chmod +x /usr/bin/deployer

ENV LFTP_HOME=/root/.lftp
ENTRYPOINT ["/usr/bin/deployer"]