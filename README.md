# akuity-migration-tools

1. Run`bin/toggle-sync.sh off` & merge (prevents self-hosted Argo CD from "fighting" Akuity)
1. Run`bin/toggle-sync.sh on`
1. Run `bin/migrate-apps.sh`
1. Merge
1. Create app-of-apps in Akuity pointing to migrated directory
1. If necessary, run `bin/add-ozzi-repocreds.sh`
1. Run `bin/update-argocd-webhooks.sh`
1. Run `bin/cleanup.sh`
