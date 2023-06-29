FROM rust:1.70-alpine3.17

# Install prerequisite
RUN apk add --no-cache bash

# Add user
RUN addgroup -S app && \
    adduser -S app -G app -h /home/app

# Set working dir and default user
WORKDIR /home/app
USER app