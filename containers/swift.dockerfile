FROM swift:5.8.1-focal as base

# Install prerequisite
RUN apt-get update -q && \
    apt-get install bash -y

# Add user
RUN groupadd --gid 1000 app && \
    useradd --uid 1000 --gid app --create-home app

# Set working dir and default user
WORKDIR /home/app
USER app