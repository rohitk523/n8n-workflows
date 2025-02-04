FROM docker.n8n.io/n8nio/n8n

USER root

# Install PostgreSQL
RUN apt-get update && apt-get install -y postgresql postgresql-contrib

# Switch to postgres user to initialize the database
USER postgres

# Initialize PostgreSQL database
RUN /etc/init.d/postgresql start && \
    psql --command "CREATE USER n8n WITH SUPERUSER PASSWORD 'n8n';" && \
    createdb -O n8n n8n

# Copy initialization script
COPY init-data.sh /docker-entrypoint-initdb.d/init-data.sh
RUN chmod +x /docker-entrypoint-initdb.d/init-data.sh

# Create start script
USER root
RUN echo '#!/bin/bash\n\
service postgresql start\n\
su - postgres -c "/docker-entrypoint-initdb.d/init-data.sh"\n\
su - node -c "n8n start"\n\
' > /start.sh && chmod +x /start.sh

# Switch back to node user
USER node

CMD ["/start.sh"]