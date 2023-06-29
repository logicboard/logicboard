FROM node:20.3.1-alpine

# Install prerequisite
RUN apk add --no-cache bash

RUN npm install -g typescript ts-node lodash underscore

WORKDIR /home/
RUN npm link typescript &&\
    npm link lodash &&\
    npm link underscore

# Add user
RUN addgroup -S app && \
    adduser -S app -G app -h /home/app

# Set working dir and default user
WORKDIR /home/app
USER app
