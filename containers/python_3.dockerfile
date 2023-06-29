FROM python:3.11-alpine

# Install prerequisite
RUN apk add --no-cache bash

# Add user
RUN addgroup -S app && \
    adduser -S app -G app -h /home/app

# Set working dir and default user
WORKDIR /home/app
USER app