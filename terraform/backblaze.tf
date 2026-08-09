# Provisions the Backblaze B2 side of the restic backups: one shared bucket
# and one append-only application key. The individual repos from
# meta.allBackupRepos are just prefixes in the bucket and need no provisioning;
# isolation between repos comes from the per-repo restic passwords.

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

# The provisioner key used by this terraform itself.
resource "b2_application_key" "provisioner" {
  key_name = "terraform-provisioner"
  capabilities = [
    "listBuckets",
    "readBuckets",
    "writeBuckets",
    "listFiles",
    "readFiles",
    "writeFiles",
    "listKeys",
    "writeKeys",
    "deleteKeys",
    "readBucketRetentions",
  ]
}

output "provisioner_key" {
  description = "The terraform provisioner key, stored in secrets/terraform_environment.age."
  sensitive   = true
  value = {
    key_id = b2_application_key.provisioner.application_key_id
    key    = b2_application_key.provisioner.application_key
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
