# pg-backup-on-sigterm

🐘 A lightweight Docker-compatible wrapper that triggers PostgreSQL backups automatically when the container receives a `SIGTERM` (e.g. during shutdown, restart, or deployment). Perfect for preserving data in Docker, Compose, or Kubernetes environments.

---

## 📦 Features

- ✅ Automatic backup on `SIGTERM` / `SIGINT`
- 📂 Per-table SQL backups with individual files
- 🧩 Restore script generator integration
- 🐳 Docker-ready, easy to plug into any container setup

---

## 🛠 Usage

### 1. Clone the repo

```bash
git clone https://github.com/Auniik/pg-backup-on-sigterm.git
cd pg-backup-on-sigterm
docker compose up

# then populate some data/schema in databse and in another terminal:
docker-compose stop
```

## 📁 Backup Output

Backups are saved to the /backups directory in the container (or host-mounted if using a volume):

```
/backups/
├── tables/
│   ├── users.sql
│   ├── orders.sql
│   └── ...
├── backup_tables.sql     # all table schemas
├── backup_data.sql       # all data
```
