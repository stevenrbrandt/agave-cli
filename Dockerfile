######################################################
#
# Agave CLI Image
# Tag: agave-cli
#
# https://bitbucket.org/agaveapi/cli
#
# This is the official image for the Agave CLI and can be used for
# parallel environment testing.
#
# docker run -it -v $HOME/.agave:/root/.agave agaveapi/cli bash
#
######################################################

FROM ubuntu:trusty

MAINTAINER Rion Dooley <dooley@tacc.utexas.edu>

# base environment and user
ENV CLI_USER rovelliana
ENV AGAVE_CLI_HOME /usr/local/agave-cli

# update dependencies
RUN apt-get update && \
    apt-get install -y git vim.tiny curl jq unzip bsdmainutils

# Create non-root user.
RUN mkdir /home/rovelliana && \
    cp /etc/skel/.bash* /home/$CLI_USER/ && \
    cp /etc/skel/.profile /home/$CLI_USER/ && \
    echo "$CLI_USER:x:6737:6737:Ngrok user:/home/$CLI_USER:/bin/false" >> /etc/passwd && \
    echo "$CLI_USER:x:6737:" >> /etc/group && \
    chown -R $CLI_USER:$CLI_USER /home/$CLI_USER && \
    chmod -R go=u,go-w /home/$CLI_USER && \
    chmod go= /home/$CLI_USER

# add CLI assets
COPY . $AGAVE_CLI_HOME

# configure environment and init default tenant
RUN chmod -R +x $AGAVE_CLI_HOME/bin && \

    # Fix the vim.tiny terminal emulation
    curl -sk 'https://bitbucket.org/!api/2.0/snippets/deardooley/AEddG/master/files/.vimrc' >> /home/$CLI_USER/.vimrc && \

    # prettyprint the terminal
    echo export PS1=\""\[\e[32;4m\]agave-cli\[\e[0m\]:\u@\h:\w$ "\" >> /home/$CLI_USER/.bashrc && \
    echo 'export PATH=$PATH:$AGAVE_CLI_HOME/bin:$AGAVE_CLI_HOME/http/bin' >> /home/$CLI_USER/.bashrc  && \
    export PATH=$PATH:$AGAVE_CLI_HOME/bin && \
    export AGAVE_CACHE_DIR=/agave && \
    tenants-init -t agave.prod && \

    chown -R rovelliana:rovelliana /agave

# configure ngrok to locally receive webhooks behind a NAT
RUN curl -sk -o /ngrok.zip 'https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip' && \
    unzip ngrok.zip -d /bin && \
    rm -f ngrok.zip && \

    $AGAVE_CLI_HOME/http/log && \
    chown -R $CLI_USER:$CLI_USER $AGAVE_CLI_HOME/http/log && \
    mkdir /.ngrok2 && \
    echo "web_addr: 0.0.0.0:4040" >> /.ngrok2/ngrok.yml && \
    chmod -R 755 /.ngrok2 && \
    echo alias ngrok_url=\''curl -s http://localhost:4040/api/tunnels | jq -r ".tunnels[0].public_url"'\' >> /home/$CLI_USER/.bashrc

# shipping a static binary to save some build time. uncomment to rebuild binary from source
#RUN apt-get install -y golang && \
#    cd $AGAVE_CLI_HOME/http && \
#    GOBIN=$AGAVE_CLI_HOME/http/bin go install src/HttpMirror.go && \
#    apt-get remove -y golang

# switch to cli user so we don't run as root
USER $CLI_USER

ENV PS1 "\[\e[32;4m\]agave-cli\[\e[0m\]:\u@\h:\w$ "
ENV HTTP_PORT 3000
ENV PATH $PATH:$AGAVE_CLI_HOME/bin:$AGAVE_CLI_HOME/http/bin
ENV AGAVE_DEVEL_MODE ''
ENV AGAVE_DEVURL ''
ENV AGAVE_CACHE_DIR /agave
ENV AGAVE_JSON_PARSER jq

EXPOSE 4040

# Runtime parameters. Start a shell by default
VOLUME /agave

CMD "/bin/bash"
