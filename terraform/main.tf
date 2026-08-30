# Do not run tofu directly — use `nix run .#terraform -- <plan|apply|...>`;
# the wrapper decrypts the credentials and state passphrase from geheimnix.
#
# The state file is encrypted with the TF_VAR_state_passphrase from
# secrets/terraform_environment.age and is committed to git.

terraform {
  required_providers {
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.13"
    }
    inwx = {
      source  = "inwx/inwx"
      version = "~> 1.0"
    }
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.45"
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
  description = "Passphrase for the state encryption. Set by the terraform wrapper from secrets/terraform_environment.age."
  type        = string
  sensitive   = true
}
