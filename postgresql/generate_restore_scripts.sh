#!/bin/bash

# Generate restore scripts
echo "📝 Generating restore scripts..."

backup_dir="/backups"

# Get table list from backup directory
tables=$(ls "$backup_dir/tables/"*.sql 2>/dev/null | sed 's|.*/||; s|\.sql||' | sort)

# 1. Interactive restore script
cat > "$backup_dir/restore.sh" << 'EOF'
#!/bin/bash

DB_NAME=${1:-${POSTGRES_DB:-mydb}}
DB_USER=${2:-${POSTGRES_USER:-postgres}}

echo "Database Restore Menu"
echo "===================="
echo "1. Complete restore (tables + data)"
echo "2. Tables only (schema)"
echo "3. Data only"
echo "4. Single table"
echo

read -p "Choose option (1-4): " choice

case $choice in
  1)
    echo "Restoring complete database..."
    psql -U "$DB_USER" -d "$DB_NAME" -f backup_tables.sql
    psql -U "$DB_USER" -d "$DB_NAME" -f backup_data.sql
    echo "✅ Complete restore finished"
    ;;
  2)
    echo "Restoring table schemas..."
    psql -U "$DB_USER" -d "$DB_NAME" -f backup_tables.sql
    echo "✅ Schema restore finished"
    ;;
  3)
    echo "Restoring data..."
    psql -U "$DB_USER" -d "$DB_NAME" -f backup_data.sql
    echo "✅ Data restore finished"
    ;;
  4)
    echo "Available tables:"
EOF

# Add table list to the script
for table in $tables; do
  echo "    echo \"  - $table\"" >> "$backup_dir/restore.sh"
done

cat >> "$backup_dir/restore.sh" << 'EOF'
    read -p "Enter table name: " table_name
    if [ -f "tables/$table_name.sql" ]; then
      echo "Restoring table: $table_name"
      psql -U "$DB_USER" -d "$DB_NAME" -f "tables/$table_name.sql"
      echo "✅ Table restored"
    else
      echo "❌ Table file not found"
    fi
    ;;
  *)
    echo "Invalid choice"
    ;;
esac
EOF

# 2. Quick restore script
cat > "$backup_dir/restore_complete.sh" << 'EOF'
#!/bin/bash

DB_NAME=${1:-${POSTGRES_DB:-mydb}}
DB_USER=${2:-${POSTGRES_USER:-postgres}}

echo "🔄 Restoring complete database..."
echo "Step 1: Restoring schemas..."
psql -U "$DB_USER" -d "$DB_NAME" -f backup_tables.sql

echo "Step 2: Restoring data..."
psql -U "$DB_USER" -d "$DB_NAME" -f backup_data.sql

echo "✅ Complete restore finished!"
EOF

# 3. Single table restore script
cat > "$backup_dir/restore_table.sh" << 'EOF'
#!/bin/bash

TABLE_NAME=$1
DB_NAME=${2:-${POSTGRES_DB:-mydb}}
DB_USER=${3:-${POSTGRES_USER:-postgres}}

if [ -z "$TABLE_NAME" ]; then
  echo "Usage: $0 <table_name> [db_name] [db_user]"
  echo "Available tables:"
EOF

# Add table list
for table in $tables; do
  echo "  echo \"  - $table\"" >> "$backup_dir/restore_table.sh"
done

cat >> "$backup_dir/restore_table.sh" << 'EOF'
  exit 1
fi

if [ ! -f "tables/$TABLE_NAME.sql" ]; then
  echo "❌ Table backup not found: tables/$TABLE_NAME.sql"
  exit 1
fi

echo "🔄 Restoring table: $TABLE_NAME"
psql -U "$DB_USER" -d "$DB_NAME" -f "tables/$TABLE_NAME.sql"
echo "✅ Table $TABLE_NAME restored!"
EOF

# Make scripts executable
chmod +x "$backup_dir/restore.sh"
chmod +x "$backup_dir/restore_complete.sh"
chmod +x "$backup_dir/restore_table.sh"

# 4. Create backup summary
cat > "$backup_dir/backup_summary.txt" << EOF
Backup Summary
==============
Date: $(date)
Database: ${POSTGRES_DB:-unknown}
Tables: $(echo $tables | wc -w)

Files Created:
- backup_tables.sql (schemas)
- backup_data.sql (data)
- restore.sh (interactive)
- restore_complete.sh (quick restore)
- restore_table.sh (single table)
- tables/ (individual backups)

Table Backups:
EOF

# Add table file sizes
for table in $tables; do
  if [ -f "$backup_dir/tables/$table.sql" ]; then
    size=$(stat -f%z "$backup_dir/tables/$table.sql" 2>/dev/null || stat -c%s "$backup_dir/tables/$table.sql" 2>/dev/null || echo "unknown")
    echo "  - $table.sql ($size bytes)" >> "$backup_dir/backup_summary.txt"
  fi
done

echo "✅ Restore scripts generated"