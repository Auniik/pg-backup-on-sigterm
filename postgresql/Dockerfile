# Use the official PostgreSQL image from Docker Hub
FROM postgres:16

# Install tini for proper signal handling
RUN apt-get update && apt-get install -y tini && rm -rf /var/lib/apt/lists/*

# Set environment variable to ensure non-interactive debconf
ENV DEBIAN_FRONTEND=noninteractive

# Create directory for backups and ensure proper permissions
RUN mkdir -p /backups \
 && chown -R postgres:postgres /backups \
 && chmod 755 /backups

# Copy custom entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

COPY generate_restore_scripts.sh /usr/local/bin/generate_restore_scripts.sh
RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/bin/generate_restore_scripts.sh

# Use tini as the init system for proper signal handling
ENTRYPOINT ["/usr/bin/tini", "--", "/usr/local/bin/entrypoint.sh"]

# Use the default PostgreSQL CMD (can be overridden)
CMD ["postgres"]