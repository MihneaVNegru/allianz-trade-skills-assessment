# Scenario 3 — GitLab resilience and monitoring

## 1. Weaknesses in the current architecture

- Single EC2 = single point of failure
- EBS is tied to one AZ
- Omnibus puts app, Redis, Gitaly, and registry on one box
- Upgrades mean downtime
- No clear recovery path for repos/artifacts (and secrets like `gitlab-secrets.json` are easy to miss)

## 2. Proposed target architecture

I'd start simple, then go full HA only if needed:

**Stage 1**
- Load balancer: NLB for SSH, ALB for HTTPS
- ASG across AZs (even a single node in an ASG is easier to replace than a hand-built instance)
- Keep RDS Multi-AZ
- ElastiCache Redis (Standalone HA, not Cluster mode)
- S3 for artifacts / LFS / uploads / backups
- Dedicated Gitaly for git repos (GitLab doesn't support network filesystems like EFS/NFS here)

**Stage 2** (if RTO still too high): Gitaly Cluster + Praefect

## 3. Monitoring practices

I'd use CloudWatch on instance, load balancer, RDS, and disk. Key alerts:
- Disk / memory (CloudWatch agent — EC2 doesn't publish these by default)
- Unhealthy hosts, 5xx, high latency
- Sidekiq queue backlog
- Failed / missing backups

I'd also add a synthetic check that actually clones a small repo, so we catch a broken Git path even when the web UI still answers 200.

## 4. Automating the runbook

I'd manage infra with Terraform and keep GitLab config in Git (Ansible / SSM).

Upgrades: backup → drain one node → upgrade → health check → repeat.

Backups go to S3 automatically, and I'd make sure the secrets file (`gitlab-secrets.json`) is included, otherwise the restored DB is unusable. I'd run restore drills on a schedule, triggered from something independent of GitLab (e.g. SSM) so it still works during an outage.
