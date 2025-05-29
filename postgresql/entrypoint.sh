#!/bin/bash

echo "🚀 Starting PostgreSQL with backup support"

# Backup function
backup_db() {
  echo "📦 Creating database backup..."
  
  backup_dir="/backups"
  tables_dir="$backup_dir/tables"
  mkdir -p "$tables_dir"

  # Get all user tables
  tables=$(psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" -t -c \
    "SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename;" \
    | tr -d ' ')

  echo "Found $(echo $tables | wc -w) tables to backup"

  # Backup each table individually
  for table in $tables; do
    if [ -n "$table" ]; then
      echo "Backing up: $table"
      pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
        --table="public.$table" \
        --clean --if-exists \
        --column-inserts \
        --no-owner --no-tablespaces --no-privileges \
        -f "$tables_dir/$table.sql" 2>/dev/null
    fi
  done

  # Backup all table schemas
  echo "Creating backup_tables.sql..."
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    --schema-only \
    --clean --if-exists \
    --no-owner --no-tablespaces --no-privileges \
    -f "$backup_dir/backup_tables.sql" 2>/dev/null

  # Backup all data
  echo "Creating backup_data.sql..."
  pg_dump -U "$POSTGRES_USER" -d "$POSTGRES_DB" \
    --data-only \
    --column-inserts \
    --no-owner --disable-triggers \
    -f "$backup_dir/backup_data.sql" 2>/dev/null

  # Generate restore scripts
  /usr/local/bin/generate_restore_scripts.sh

  echo "✅ Backup completed"
}

# Cleanup function for graceful shutdown
cleanup() {
  echo "🔄 Shutting down - creating backup..."
  backup_db
  echo "🛑 Stopping PostgreSQL..."
  kill -TERM "$postgres_pid"
  wait "$postgres_pid"
  exit 0
}

# Set up signal handlers
trap cleanup SIGTERM SIGINT

# Start PostgreSQL in background
docker-entrypoint.sh "$@" &
postgres_pid=$!

echo "✅ PostgreSQL started (PID: $postgres_pid)"

# Wait for PostgreSQL process
wait "$postgres_pid"