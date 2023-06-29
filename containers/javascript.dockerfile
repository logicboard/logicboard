FROM node:20.3.1-alpine

# Install prerequisite
RUN apk add --no-cache bash

RUN npm install -g lodash underscore

WORKDIR /home/
RUN npm link lodash underscore

# Add user
RUN addgroup -S app && \
    adduser -S app -G app -h /home/app

# Set working dir and default user
WORKDIR /home/app
USER app
