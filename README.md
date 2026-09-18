# Hotel Bookings DevOps Assessment

This repository demonstrates an AWS Terraform design and a local PostgreSQL reliability workflow. AWS deployment is intentionally not required; Terraform is validated and planned without applying resources.

## Repository layout

```text
infra/
  modules/network   VPC, public/private subnets, routes, NAT
  modules/ecs       ALB, ECS/Fargate, task definition, security groups
  modules/rds       private PostgreSQL RDS and security group
  envs/dev          small resources, 3-day backups, no deletion protection
  envs/prod         larger resources, 14-day backups, deletion protection

db/migrations/      schema, indexes, and deterministic seed data
scripts/             backup and restore commands
.github/workflows/   Terraform fmt, init, validate, and plan checks
```

## Prerequisites

- Docker Desktop with Docker Compose
- Terraform 1.5 or newer for infrastructure checks
- Bash (Git Bash, WSL, or a Linux/macOS shell) for the scripts

## Run the local database

From the repository root:

```bash
docker compose up -d

docker compose ps
```

The database is available at `localhost:5432` with database `bookings`, user `bookings`, and password `bookings`. The first startup runs the SQL files in `db/migrations/` and creates 120 bookings plus booking events.

To rerun the migrations from a clean database after changing the SQL files, use `docker compose down -v` and then `docker compose up -d`.

Verify the seed and the target query:

```bash
docker compose exec -T db psql -U bookings -d bookings -c "SELECT COUNT(*) AS bookings FROM hotel_bookings;"
docker compose exec -T db psql -U bookings -d bookings -c "SELECT org_id, status, COUNT(*), SUM(amount) FROM hotel_bookings WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days' GROUP BY org_id, status;"
```

The index `idx_hotel_bookings_city_created_org_status` starts with `city, created_at`, matching the equality and range predicates. PostgreSQL can use those leading columns to narrow the rows before grouping by `org_id` and `status`; the included grouping columns also reduce heap lookups for index-only plans when visibility permits. Check the plan with:

```bash
docker compose exec -T db psql -U bookings -d bookings -c "EXPLAIN (ANALYZE, BUFFERS) SELECT org_id, status, COUNT(*), SUM(amount) FROM hotel_bookings WHERE city = 'delhi' AND created_at >= NOW() - INTERVAL '30 days' GROUP BY org_id, status;"
```

## Backup and restore

Create a timestamped custom-format dump:

```bash
bash scripts/backup.sh
```

Restore a dump into a freshly recreated database:

```bash
bash scripts/restore.sh backups/bookings_<timestamp>.dump
```

Verify the restored content and event relationship:

```bash
docker compose exec -T db psql -U bookings -d bookings -c "SELECT COUNT(*) AS bookings FROM hotel_bookings;"
docker compose exec -T db psql -U bookings -d bookings -c "SELECT COUNT(*) AS events FROM booking_events;"
docker compose exec -T db psql -U bookings -d bookings -c "SELECT COUNT(*) AS linked_events FROM booking_events e JOIN hotel_bookings b ON b.id = e.booking_id;"
```

Expected results are 120 bookings, more than zero events, and the linked event count equal to the event count.

## Terraform checks

Each environment has separate variables, tfvars, and a backend state path. The example uses a local backend so checks do not require an S3 bucket. Run the checks from each environment directory:

```bash
cd infra/envs/dev
terraform init
terraform fmt -check -recursive ../..
terraform validate
terraform plan -refresh=false -input=false -var-file=dev.tfvars

cd ../prod
terraform init
terraform validate
terraform plan -refresh=false -input=false -var-file=prod.tfvars
```

The two plans intentionally differ: dev uses `db.t4g.micro`, one task, three days of retention, and no deletion protection. Prod uses `db.t4g.medium`, two tasks, fourteen days of retention, Multi-AZ, and deletion protection. Neither environment should be applied for this assessment.

The GitHub Actions workflow runs formatting, backend-free initialization, validation, and a refresh-free plan for both environments on pull requests and pushes to `main`. Plan files are uploaded as workflow artifacts.

## Security design notes

- ALB ingress is public on HTTP port 80.
- ECS tasks run in private subnets and accept port 80 only from the ALB security group.
- RDS is not publicly accessible and accepts PostgreSQL only from the ECS security group.
- RDS storage is encrypted and the ECS task role is limited to the AWS-managed execution policy needed by Fargate.
- The sample uses one NAT gateway for cost-conscious demonstration. A production deployment would normally use one per availability zone and add HTTPS with ACM.
