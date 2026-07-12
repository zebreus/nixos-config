# Provisions the Backblaze B2 side of the restic backups: one shared bucket
# and one append-only application key. The individual repos from
# meta.allBackupRepos are just prefixes in the bucket and need no provisioning;
# isolation between repos comes from the per-repo restic passwords.
#
# Do not run tofu directly — use `nix run .#terraform -- <plan|apply|...>`.
# The wrapper decrypts the B2 provisioner key and the state passphrase from
# agenix, and `nix run .#sync-restic-secrets` stores the application key and
# fresh per-repo restic passwords with agenix.
#
# The state file is encrypted with the passphrase from
# secrets/terraform_state_passphrase.age and is committed to git.

terraform {
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.13"
    }
  }

  encryption {
    key_provider "pbkdf2" "state" {
      passphrase = var.state_passphrase
    }
    method "aes_gcm" "state" {
      keys = key_provider.pbkdf2.state
    }
    state {
      method   = method.aes_gcm.state
      enforced = true
    }
    plan {
      method   = method.aes_gcm.state
      enforced = true
    }
  }
}

variable "state_passphrase" {
  description = "Passphrase for the state encryption. Set by the terraform wrapper from secrets/terraform_state_passphrase.age."
  type        = string
  sensitive   = true
}

# Credentials come from the B2_APPLICATION_KEY_ID / B2_APPLICATION_KEY
# environment variables (the provisioner key, from
# secrets/terraform_environment.age).
provider "b2" {}

# Must match meta.services.backup.bucket in machines.nix.
resource "b2_bucket" "backups" {
  bucket_name = "zebreus-backup"
  bucket_type = "allPrivate"

  # Hidden (i.e. deleted by restic) files are kept for 30 days before they are
  # actually deleted. Until then they can be restored with the master key, so a
  # compromised client cannot permanently destroy any repository.
  lifecycle_rules {
    file_name_prefix             = ""
    days_from_hiding_to_deleting = 30
  }
}

# The single append-only key shared by all machines. No deleteFiles capability:
# it can create and hide files, but cannot delete any file version for good.
resource "b2_application_key" "append_only" {
  key_name     = "zebreus-backup-append-only"
  bucket_ids   = [b2_bucket.backups.bucket_id]
  capabilities = ["listBuckets", "listFiles", "readFiles", "writeFiles"]
}

output "application_key" {
  description = "The append-only application key, consumed by sync-restic-secrets."
  sensitive   = true
  value = {
    key_id = b2_application_key.append_only.application_key_id
    key    = b2_application_key.append_only.application_key
  }
}
