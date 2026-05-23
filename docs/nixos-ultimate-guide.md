# NixOS Ultimate Homelab Guide

> **7 goals · 6 phases · ordered by priority.**
> Complete each phase before moving to the next. This guide is designed for building a reproducible homelab, a portable dev environment, automated fleet management, customer VMs, and local AI — all on NixOS.

---

## Table of Contents

1. [Core Resources](#core-resources)
2. [Phase 1 — Foundation: Flakes, Modules & First Homelab Services](#phase-1--foundation-flakes-modules--first-homelab-services)
3. [Phase 2 — Hardening, Persistence & Reproducibility](#phase-2--hardening-persistence--reproducibility)
4. [Phase 3 — Remote Auto-Updates & Bulk Provisioning](#phase-3--remote-auto-updates--bulk-provisioning)
5. [Phase 4 — Dev Environment: Neovim/Helix + Home Manager](#phase-4--dev-environment-neovimhelix--home-manager)
6. [Phase 5 — Customer VMs & Managed Infrastructure](#phase-5--customer-vms--managed-infrastructure)
7. [Phase 6 — Hardware Repurposing & Local AI](#phase-6--hardware-repurposing--local-ai)
8. [Quick Reference Commands](#quick-reference-commands)
9. [Goal-to-Phase Mapping](#goal-to-phase-mapping)

---

## Core Resources

| Resource | URL | When to use |
|---|---|---|
| NixOS Manual (stable) | https://nixos.org/manual/nixos/stable/ | Primary reference for all NixOS options |
| NixOS Wiki | https://wiki.nixos.org/wiki/NixOS_Wiki | Service-specific setup guides |
| nix.dev tutorials | https://nix.dev/tutorials/nixos/index.html | Language basics, flakes intro |
| NixOS & Flakes Book | https://nixos-and-flakes.thiscute.world/introduction/ | Deep flakes patterns, multi-host configs |
| vimjoyer YouTube | https://www.youtube.com/@vimjoyer | Practical walkthroughs for every topic |
| vimjoyer GitHub | https://github.com/vimjoyer/ | Example configs referenced in videos |
| NixOS Options Search | https://search.nixos.org/options | Search all available NixOS module options |
| NixOS Packages Search | https://search.nixos.org/packages | Find package names |
| Home Manager Options | https://home-manager-options.extranix.com | All Home Manager options searchable |
| nixvim | https://github.com/nix-community/nixvim | Declarative Neovim configuration in Nix |

---

## Phase 1 — Foundation: Flakes, Modules & First Homelab Services

**Goals covered:** Goal 1 (Part A)
**Estimated time:** 2–4 weeks
**Start here.** Install NixOS on your homelab machine first. Everything else builds on this. Use the stable ISO from https://nixos.org/download.

---

### Step 1: Core Concepts to Learn First

Before writing any service config, understand these three things:

**1. Nix language basics**
- Attributes, `let`/`in`, imports, functions, and `with`
- Resource: [nix.dev — Nix language basics](https://nix.dev/tutorials/nix-language.html)

**2. Flakes**
- `flake.nix` inputs/outputs, `nixosConfigurations`, `nix flake update`
- Resource: [vimjoyer — "NixOS Flakes Explained"](https://www.youtube.com/@vimjoyer)
- Resource: [NixOS & Flakes Book — Chapters 1–3](https://nixos-and-flakes.thiscute.world/introduction/)

**3. The module system**
- `options`, `config`, `imports`, and how modules compose
- Resource: [NixOS Manual — Options](https://nixos.org/manual/nixos/stable/#sec-writing-modules)
- Resource: vimjoyer — "NixOS Modules Explained"

---

### Step 2: Repository Structure

Set up this directory layout from day one. Adding structure later is painful.

```
nixos-config/
├── flake.nix                     # entry point — defines all hosts
├── flake.lock                    # pinned input versions — commit this
├── hosts/
│   ├── homelab/
│   │   ├── default.nix           # hardware + host-specific config
│   │   └── hardware-configuration.nix
│   ├── desktop/
│   │   ├── default.nix
│   │   └── hardware-configuration.nix
│   ├── laptop/
│   │   └── default.nix
│   ├── inspiron2200/
│   │   └── default.nix           # minimal terminal-only profile
│   └── common/
│       └── default.nix           # shared: locale, SSH, firewall, base packages
├── modules/
│   ├── services/
│   │   ├── caddy.nix
│   │   ├── immich.nix
│   │   ├── nextcloud.nix
│   │   ├── jellyfin.nix
│   │   ├── adguardhome.nix
│   │   └── netbird.nix
│   ├── base.nix                  # users, locale, SSH, firewall
│   ├── desktop.nix               # GUI-specific: Niri/Hyprland, fonts, apps
│   └── dev.nix                   # dev tools, shell config
├── home/                         # Phase 4: Home Manager configs
│   ├── common.nix
│   ├── neovim.nix
│   └── shell.nix
└── secrets/                      # agenix/sops encrypted secrets
    ├── secrets.nix               # declares which keys can decrypt what
    └── nextcloud-adminpass.age
```

**Starter `flake.nix`:**

```nix
{
  description = "NixOS homelab configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, agenix, nixos-hardware, disko, ... }@inputs:
  let
    mkHost = hostname: nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/${hostname}/default.nix
        ./hosts/common/default.nix
        agenix.nixosModules.default
        disko.nixosModules.disko
      ];
    };
  in {
    nixosConfigurations = {
      homelab   = mkHost "homelab";
      desktop   = mkHost "desktop";
      laptop    = mkHost "laptop";
      inspiron  = mkHost "inspiron2200";
    };
  };
}
```

---

### Step 3: Secrets Management (Set Up Before Any Service)

> **Warning:** Never put passwords or API keys directly in your Nix config. Use **agenix** or **sops-nix** from day one — retrofitting secrets later is painful and requires rebuilding configs.

**Recommended: agenix** (simpler to start)
- GitHub: https://github.com/ryantm/agenix
- vimjoyer video: "NixOS Secrets with Agenix"

**Alternative: sops-nix** (more powerful, supports non-Nix secret consumers)
- GitHub: https://github.com/Mic92/sops-nix

**agenix setup:**

```nix
# secrets/secrets.nix — declare which SSH keys can decrypt each secret
let
  homelab = "ssh-ed25519 AAAAC3... root@homelab";
  myKey   = "ssh-ed25519 AAAAC3... user@laptop";
in {
  "nextcloud-adminpass.age".publicKeys = [ homelab myKey ];
  "immich-db-pass.age".publicKeys      = [ homelab myKey ];
}
```

```bash
# Encrypt a secret
agenix -e secrets/nextcloud-adminpass.age
```

```nix
# Use in a module
age.secrets.nextcloud-adminpass.file = ../../secrets/nextcloud-adminpass.age;
services.nextcloud.config.adminpassFile = config.age.secrets.nextcloud-adminpass.path;
```

---

### Step 4: Services (Configure in This Order)

Configure services from simplest to most complex. Each one teaches you something you need for the next.

#### 1. AdGuard Home (simplest — pure NixOS module)

```nix
# modules/services/adguardhome.nix
{ config, ... }: {
  services.adguardhome = {
    enable = true;
    mutableSettings = false;       # declarative — settings managed by Nix
    settings = {
      dns = {
        upstream_dns = [ "https://dns10.quad9.net/dns-query" "https://cloudflare-dns.com/dns-query" ];
        bootstrap_dns = [ "9.9.9.9" "1.1.1.1" ];
      };
      http.address = "0.0.0.0:3000";
    };
  };
  networking.firewall.allowedTCPPorts = [ 53 3000 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
```

- Wiki: https://wiki.nixos.org/wiki/AdGuard_Home

#### 2. Caddy (reverse proxy — configure second, wraps everything)

```nix
# modules/services/caddy.nix
{ config, ... }: {
  services.caddy = {
    enable = true;
    virtualHosts = {
      "nextcloud.yourdomain.com".extraConfig = ''
        reverse_proxy localhost:8080
      '';
      "immich.yourdomain.com".extraConfig = ''
        reverse_proxy localhost:2283
      '';
      "jellyfin.yourdomain.com".extraConfig = ''
        reverse_proxy localhost:8096
      '';
      "adguard.yourdomain.com".extraConfig = ''
        reverse_proxy localhost:3000
      '';
    };
  };
  networking.firewall.allowedTCPPorts = [ 80 443 ];
}
```

- Wiki: https://wiki.nixos.org/wiki/Caddy

#### 3. Netbird Client (VPN overlay — needed before remote management)

```nix
# modules/services/netbird.nix
{ pkgs, ... }: {
  environment.systemPackages = [ pkgs.netbird ];
  systemd.services.netbird = {
    enable = true;
    description = "Netbird VPN client";
    serviceConfig = {
      ExecStart = "${pkgs.netbird}/bin/netbird up";
      Restart = "always";
    };
    wantedBy = [ "multi-user.target" ];
  };
}
```

- Netbird docs: https://docs.netbird.io/how-to/installation

#### 4. Nextcloud

```nix
# modules/services/nextcloud.nix
{ config, pkgs, ... }: {
  services.nextcloud = {
    enable = true;
    hostName = "nextcloud.yourdomain.com";
    package = pkgs.nextcloud29;
    database.createLocally = true;
    config = {
      dbtype = "pgsql";
      adminpassFile = config.age.secrets.nextcloud-adminpass.path;
    };
    settings = {
      trusted_domains = [ "nextcloud.yourdomain.com" ];
      default_phone_region = "US";
    };
  };
}
```

- Wiki: https://wiki.nixos.org/wiki/Nextcloud

#### 5. Immich (Photo management)

```nix
# modules/services/immich.nix
{ config, ... }: {
  services.immich = {
    enable = true;
    host = "0.0.0.0";
    port = 2283;
    mediaLocation = "/data/immich";
    database.createLocally = true;
  };
}
```

> **Note:** Requires PostgreSQL with `pgvecto.rs` extension. Check the current NixOS Wiki page for your version — this config evolves frequently.
- Wiki: https://wiki.nixos.org/wiki/Immich

#### 6. Jellyfin ("Nixflix")

```nix
# modules/services/jellyfin.nix
{ config, ... }: {
  services.jellyfin = {
    enable = true;
    openFirewall = true;
  };
  users.users.jellyfin.extraGroups = [ "video" "render" ];  # for GPU transcoding
}
```

- Wiki: https://wiki.nixos.org/wiki/Jellyfin

---

### vimjoyer Videos to Watch (Phase 1, in order)

1. "Ultimate NixOS Guide" — overview, watch first
2. "Nix Flakes Explained" — flake.nix structure
3. "Modular NixOS Config" — module system deep dive
4. "NixOS Secrets with Agenix" — before touching any service passwords
5. "Caddy Reverse Proxy on NixOS"

All videos: https://www.youtube.com/@vimjoyer

---

## Phase 2 — Hardening, Persistence & Reproducibility

**Goals covered:** Goal 1 (Part B), Goal 5 (best practices)
**Estimated time:** 1–2 weeks

---

### Step 1: Make Your Config Truly Reproducible

**Pin all inputs:**
```bash
# Always commit flake.lock
git add flake.lock
git commit -m "chore: pin flake inputs"
```

**Use nixos-hardware for machine-specific tuning:**
```nix
inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-carbon-gen9
# or for common hardware:
inputs.nixos-hardware.nixosModules.common-cpu-amd
inputs.nixos-hardware.nixosModules.common-gpu-nvidia
```
- GitHub: https://github.com/NixOS/nixos-hardware

**Never change `stateVersion` after first install:**
```nix
system.stateVersion = "24.05";  # set once, never touch again
```

**Declare explicit data directories:**
```nix
# Know what is state vs config
fileSystems."/data" = {
  device = "/dev/disk/by-label/data";
  fsType = "ext4";
};
```

**Consider the impermanence module** (makes state fully explicit — everything not listed is wiped on reboot):
- GitHub: https://github.com/nix-community/impermanence

**Automatic garbage collection:**
```nix
nix.gc = {
  automatic = true;
  dates = "weekly";
  options = "--delete-older-than 30d";
};
nix.settings.auto-optimise-store = true;
```

---

### Step 2: Scalability Patterns (Goal 5)

**`mkHost` helper function** — stamp out new machines with 3 lines:

```nix
# flake.nix
let
  mkHost = { hostname, system ? "x86_64-linux", extraModules ? [] }:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = { inherit inputs; };
      modules = [
        ./hosts/${hostname}/default.nix
        ./hosts/common/default.nix
        agenix.nixosModules.default
      ] ++ extraModules;
    };
in {
  nixosConfigurations = {
    homelab  = mkHost { hostname = "homelab"; };
    desktop  = mkHost { hostname = "desktop"; extraModules = [ ./modules/desktop.nix ]; };
    inspiron = mkHost { hostname = "inspiron2200"; extraModules = [ ./modules/minimal.nix ]; };
  };
}
```

**Per-service toggles with `mkEnableOption`:**

```nix
# modules/services/immich.nix
{ config, lib, pkgs, ... }:
let cfg = config.homelab.services.immich;
in {
  options.homelab.services.immich = {
    enable = lib.mkEnableOption "Immich photo server";
  };
  config = lib.mkIf cfg.enable {
    services.immich.enable = true;
    # ... rest of config
  };
}
```

**Machine role tags:**

```nix
# hosts/common/default.nix
{ config, lib, ... }: {
  options.homelab = {
    isServer  = lib.mkEnableOption "server role";
    isDesktop = lib.mkEnableOption "desktop role";
    isDev     = lib.mkEnableOption "dev tools role";
    isMinimal = lib.mkEnableOption "minimal terminal-only role";
  };
}

# hosts/homelab/default.nix
{ ... }: {
  homelab.isServer = true;
  homelab.isDev = true;
}
```

**Overlays — keep minimal:**
```nix
# Document every overlay. Overlays are the #1 source of reproducibility breaks.
nixpkgs.overlays = [
  # Only add overlays that are truly necessary
  # Each overlay increases surface area for breakage
];
```

**Resources:**
- [NixOS & Flakes Book — Chapter 5: Best Practices](https://nixos-and-flakes.thiscute.world/best-practices/intro)
- [NixOS Manual — Writing Modules](https://nixos.org/manual/nixos/stable/#sec-writing-modules)

---

## Phase 3 — Remote Auto-Updates & Bulk Provisioning

**Goals covered:** Goal 3 (auto-update on git push), Goal 4 (bulk provisioning)
**Estimated time:** 1–2 weeks

---

### Goal 3: Auto-Update on Git Push

Two approaches — choose based on trust model.

#### Option A: Pull-based (recommended for remote/customer machines)

Each machine runs a systemd timer that periodically pulls from your GitHub branch and rebuilds. Safe: no inbound ports needed, machines control their own update timing.

```nix
# Add to each host's config
systemd.services.nixos-autoupgrade = {
  description = "NixOS auto-upgrade from GitHub";
  path = [ pkgs.git pkgs.nix pkgs.nixos-rebuild ];
  serviceConfig = {
    Type = "oneshot";
    ExecStart = pkgs.writeShellScript "nixos-upgrade" ''
      set -e
      nixos-rebuild switch \
        --flake github:youruser/nixos-config#${config.networking.hostName} \
        --refresh
    '';
  };
};

systemd.timers.nixos-autoupgrade = {
  description = "NixOS auto-upgrade timer";
  timerConfig = {
    OnCalendar = "04:00";         # run at 4am daily
    RandomizedDelaySec = "1h";    # stagger across machines
    Persistent = true;
  };
  wantedBy = [ "timers.target" ];
};
```

**Rollback strategy — set this up before enabling auto-updates:**
```nix
boot.loader.systemd-boot.configurationLimit = 5;  # keep 5 generations
# Manual rollback: sudo nixos-rebuild switch --rollback
# Or at boot: select previous generation in bootloader
```

#### Option B: Push-based with Colmena (for machines you control directly)

[Colmena](https://github.com/zhaofengli/colmena) manages a fleet from a single config. Run from your local machine or a GitHub Actions runner.

```nix
# colmena.nix (or inside flake.nix outputs)
{
  meta = {
    nixpkgs = import nixpkgs { system = "x86_64-linux"; };
  };

  defaults = { pkgs, ... }: {
    imports = [ ./hosts/common/default.nix ];
  };

  homelab = { name, nodes, pkgs, ... }: {
    imports = [ ./hosts/homelab/default.nix ];
    deployment = {
      targetHost = "homelab.yourdomain.com";
      targetUser = "root";
    };
  };

  customer-site-1 = { ... }: {
    imports = [ ./hosts/customer1/default.nix ];
    deployment.targetHost = "10.0.0.5";  # via Netbird VPN
  };
}
```

```bash
# Deploy to all machines
colmena apply

# Deploy to one machine
colmena apply --on homelab

# Deploy and reboot
colmena apply --reboot
```

#### Option C: deploy-rs (lightweight push-based)

```bash
nix run github:serokell/deploy-rs -- .#homelab
```
- GitHub: https://github.com/serokell/deploy-rs

#### GitHub Actions workflow (optional CI/CD):

```yaml
# .github/workflows/deploy.yml
name: Deploy NixOS configs
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: cachix/install-nix-action@v27
        with:
          extra_nix_config: "experimental-features = nix-command flakes"
      - name: Deploy via Colmena
        run: |
          nix run github:zhaofengli/colmena -- apply
        env:
          SSH_PRIVATE_KEY: ${{ secrets.DEPLOY_SSH_KEY }}
```

> **Warning:** Set up a tested rollback strategy before enabling any auto-update mechanism. Test `nixos-rebuild switch --rollback` manually before automating.

---

### Goal 4: Bulk Provisioning New Machines

The key combo: **nixos-anywhere** + **disko** + your flake config.

**nixos-anywhere** installs NixOS onto any machine with SSH access (even non-NixOS) from your config in one command.
- GitHub: https://github.com/nix-community/nixos-anywhere
- vimjoyer video: "nixos-anywhere + disko"

```bash
# Install NixOS onto a new machine in one command
nix run github:nix-community/nixos-anywhere -- \
  --flake .#homelab \
  root@192.168.1.100
```

**disko** — declarative disk partitioning, used by nixos-anywhere during install:
- GitHub: https://github.com/nix-community/disko

```nix
# hosts/homelab/disk-config.nix
{ ... }: {
  disko.devices = {
    disk = {
      sda = {
        type = "disk";
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
```

**For ZFS (recommended for homelab with data persistence):**

```nix
# disko config with ZFS
root = {
  size = "100%";
  content = {
    type = "zfs";
    pool = "zroot";
  };
};
# Then define ZFS datasets separately
```

**Zero-touch installer ISO** (for truly unattended provisioning):

```nix
# Build a custom installer ISO that auto-installs from your config
nixos-generators -f iso -c ./installer.nix
```
- GitHub: https://github.com/nix-community/nixos-generators

---

## Phase 4 — Dev Environment: Neovim/Helix + Home Manager

**Goals covered:** Goal 2
**Estimated time:** 2–3 weeks initial setup, ongoing refinement

---

### Helix vs Neovim — Which to Choose

| | Helix | Neovim |
|---|---|---|
| Plugin system | None (batteries included) | Extensive ecosystem |
| AI integrations | Limited | Excellent (avante, codecompanion, codeium, copilot) |
| Config format | TOML (simple) | Lua/Nix via nixvim |
| RAM usage | Very low | Low–Medium |
| LSP support | Built-in | Via plugins |
| Best for | Dell Inspiron 2200 (minimal) | Main dev machines |
| Declarative via Nix | `programs.helix` | nixvim flake |

**Recommendation: Neovim with nixvim** for your main machines. Helix as the profile for the Dell Inspiron 2200. Both managed via Home Manager.

- Helix site: https://helix-editor.com
- nixvim: https://github.com/nix-community/nixvim

---

### Home Manager Setup

```nix
# flake.nix — add home-manager module to each host
modules = [
  ./hosts/${hostname}/default.nix
  home-manager.nixosModules.home-manager
  {
    home-manager.useGlobalPkgs = true;
    home-manager.useUserPackages = true;
    home-manager.users.youruser = import ./home/default.nix;
  }
];
```

Resources:
- vimjoyer: "Home Manager" video
- [Home Manager Manual](https://nix-community.github.io/home-manager/)
- [Home Manager Options Search](https://home-manager-options.extranix.com)

---

### Neovim via nixvim (fully declarative)

All plugins, keybinds, and settings in Nix — zero manual `:PackerSync`.

```nix
# home/neovim.nix
{ inputs, ... }: {
  imports = [ inputs.nixvim.homeManagerModules.nixvim ];

  programs.nixvim = {
    enable = true;
    colorschemes.catppuccin.enable = true;

    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      wrap = false;
    };

    plugins = {
      # LSP
      lsp = {
        enable = true;
        servers = {
          nixd.enable = true;           # Nix LSP
          rust-analyzer.enable = true;
          pyright.enable = true;
          ts-ls.enable = true;
          lua-ls.enable = true;
        };
      };

      # Syntax highlighting
      treesitter = {
        enable = true;
        settings.highlight.enable = true;
      };

      # Fuzzy finding
      telescope = {
        enable = true;
        keymaps = {
          "<leader>ff" = "find_files";
          "<leader>fg" = "live_grep";
          "<leader>fb" = "buffers";
          "<leader>fh" = "help_tags";
          "<leader>gs" = "git_status";
        };
      };

      # File tree
      neo-tree.enable = true;

      # Completion
      cmp = {
        enable = true;
        autoEnableSources = true;
        settings.sources = [
          { name = "nvim_lsp"; }
          { name = "path"; }
          { name = "buffer"; }
        ];
      };

      # Git integration
      gitsigns.enable = true;
      lazygit.enable = true;

      # Status line
      lualine.enable = true;
    };

    # Key mappings
    globals.mapleader = " ";
    keymaps = [
      { key = "<leader>e"; action = ":Neotree toggle<CR>"; }
      { key = "<leader>lg"; action = ":LazyGit<CR>"; }
      { key = "<leader>ca"; action.__raw = "vim.lsp.buf.code_action"; }
      { key = "gd"; action.__raw = "vim.lsp.buf.definition"; }
      { key = "K";  action.__raw = "vim.lsp.buf.hover"; }
      { key = "<leader>rn"; action.__raw = "vim.lsp.buf.rename"; }
    ];
  };
}
```

---

### AI Integration in Neovim

**avante.nvim** (recommended — supports custom endpoints, OpenAI-compatible):
- GitHub: https://github.com/yetone/avante.nvim

```nix
# In your nixvim config
extraPlugins = with pkgs.vimPlugins; [
  avante-nvim
];
extraConfigLua = ''
  require('avante').setup({
    provider = "openai",
    openai = {
      endpoint = vim.env.AVANTE_API_ENDPOINT or "https://api.openai.com/v1",
      model = vim.env.AVANTE_MODEL or "gpt-4o",
      api_key_name = "AVANTE_API_KEY",
    },
  })
'';
```

**codecompanion.nvim** (alternative — multi-provider, good for Ollama):
- GitHub: https://github.com/olimorris/codecompanion.nvim

```lua
-- Point at local Ollama (Phase 6)
adapters = {
  ollama = require("codecompanion.adapters").extend("ollama", {
    schema = { model = { default = "llama3.1:8b" } },
    url = "http://ai.home.yourdomain.com:11434",
  }),
}
```

> **Store API keys as agenix/sops secrets, not in your flake. Set the endpoint via environment variable so you can swap between local Ollama (Phase 6) and cloud APIs without changing your Nix config.**

---

### Helix Config (for Dell Inspiron 2200)

```nix
# hosts/inspiron2200/default.nix
{ config, pkgs, ... }: {
  imports = [ ./hardware-configuration.nix ];

  # Minimal: TTY only, auto-login, helix + essential tools
  services.getty.autologinUser = "youruser";

  programs.helix = {
    enable = true;
    settings = {
      theme = "base16_terminal";
      editor = {
        line-number = "relative";
        cursor-shape.insert = "bar";
        indent-guides.render = true;
      };
      keys.normal = {
        space.f = ":open ~/.config/helix/config.toml";
        space.space = "file_picker";
      };
    };
    languages.language = [
      { name = "nix"; language-servers = [ "nil" ]; }
      { name = "rust"; language-servers = [ "rust-analyzer" ]; }
    ];
  };

  environment.systemPackages = with pkgs; [
    helix
    tmux
    git
    ripgrep
    fd
    bat
    btop
    nil              # Nix LSP
    rust-analyzer
    nodejs           # for some LSPs
  ];
}
```

---

### Niri Wayland Compositor (desktop/laptop)

Niri is a scrolling tiling Wayland compositor — excellent for the keyboard-first workflow.
- GitHub: https://github.com/YaLTeR/niri
- Wiki: https://wiki.nixos.org/wiki/Niri

```nix
# modules/desktop.nix (for desktop/laptop, not inspiron)
{ ... }: {
  programs.niri = {
    enable = true;
    settings = {
      # configure via home-manager niri module
    };
  };
  environment.sessionVariables.NIXOS_OZONE_WL = "1";  # Electron Wayland
}
```

---

### vimjoyer Videos for Phase 4

1. "Home Manager" — start here before anything else
2. "nixvim" — fully declarative Neovim config in Nix
3. "Nix Develop & Devshells" — per-project dev environments (critical for multi-language work)
4. "NixOS on Laptops" — power management, suspend, etc.

---

### Essential Neovim Keybinds Reference

| Mode | Key | Action |
|---|---|---|
| Normal | `<Space>` | Leader key |
| Normal | `<leader>ff` | Find files (Telescope) |
| Normal | `<leader>fg` | Live grep |
| Normal | `<leader>fb` | Buffers |
| Normal | `<leader>e` | Toggle file tree |
| Normal | `gd` | Go to definition |
| Normal | `gr` | Go to references |
| Normal | `K` | Hover documentation |
| Normal | `<leader>ca` | Code action |
| Normal | `<leader>rn` | Rename symbol |
| Normal | `<leader>lg` | LazyGit |
| Normal | `<C-h/j/k/l>` | Navigate splits |
| Normal | `<leader>w` | Save file |
| Normal | `<leader>q` | Quit |
| Insert | `<C-space>` | Trigger completion |
| Insert | `<Tab>` | Next completion item |

---

## Phase 5 — Customer VMs & Managed Infrastructure

**Goals covered:** Goal 6
**Estimated time:** 2–4 weeks

---

### Architecture Overview

```
NixOS Host (your managed layer)
├── networking, firewall, Netbird VPN, Caddy reverse proxy
├── ZFS storage pool (persistent data)
├── systemd units managing VM lifecycle
└── QEMU/KVM VMs
    ├── Customer VM 1 (ZimaOS / any Linux)
    │   └── qcow2 disk at /data/vms/customer1.qcow2 [STATE — survives rebuild]
    └── Customer VM 2
        └── qcow2 disk at /data/vms/customer2.qcow2
```

**Key principle:** `nixos-rebuild switch` on the host only affects the NixOS layer. VM disks are plain files — completely untouched by Nix rebuilds.

---

### Host Setup

```nix
# modules/virtualisation.nix
{ pkgs, ... }: {
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = false;
      ovmf.enable = true;        # UEFI firmware
    };
  };

  users.users.youruser.extraGroups = [ "libvirtd" "kvm" ];

  environment.systemPackages = with pkgs; [
    virt-manager         # GUI VM manager
    virt-viewer
    qemu_kvm
    libvirt
  ];
}
```

---

### Customer VM with Persistent Disk

```nix
# VM definition as a systemd service
# The qcow2 disk persists across nixos-rebuild switch

systemd.services."vm-customer1" = {
  description = "Customer 1 VM";
  after = [ "network.target" "libvirtd.service" ];
  wantedBy = [ "multi-user.target" ];
  path = [ pkgs.qemu_kvm pkgs.libvirt ];
  serviceConfig = {
    Type = "forking";
    ExecStartPre = pkgs.writeShellScript "vm-init" ''
      if [ ! -f /data/vms/customer1.qcow2 ]; then
        qemu-img create -f qcow2 /data/vms/customer1.qcow2 100G
      fi
    '';
    ExecStart = ''
      ${pkgs.qemu_kvm}/bin/qemu-system-x86_64 \
        -enable-kvm \
        -m 4G \
        -smp 4 \
        -drive file=/data/vms/customer1.qcow2,format=qcow2 \
        -net nic -net user,hostfwd=tcp::2222-:22 \
        -daemonize -pidfile /run/vm-customer1.pid
    '';
    ExecStop = "kill $(cat /run/vm-customer1.pid)";
    PIDFile = "/run/vm-customer1.pid";
  };
};
```

---

### VFIO GPU/USB Passthrough

```nix
# For passing GPU or USB devices through to a VM
# Requires CPU with VT-d (Intel) or AMD-Vi

boot.kernelParams = [
  "intel_iommu=on"      # Intel: use this
  # "amd_iommu=on"      # AMD: use this instead
  "iommu=pt"
  "vfio-pci.ids=10de:2484,10de:228b"  # your GPU PCI IDs
];

boot.initrd.kernelModules = [ "vfio_pci" "vfio" "vfio_iommu_type1" ];

# Find your GPU's PCI IDs:
# lspci -nn | grep -i nvidia
```

- Wiki: https://wiki.nixos.org/wiki/VFIO

---

### ZFS for VM Storage (Recommended)

```nix
# Give VMs their own ZFS dataset — easy snapshots before updates

boot.supportedFilesystems = [ "zfs" ];
networking.hostId = "12345678";  # required by ZFS — generate with: head -c 8 /etc/machine-id

services.zfs.autoScrub.enable = true;
services.zfs.autoSnapshot = {
  enable = true;
  frequent = 4;
  hourly = 24;
  daily = 7;
  weekly = 4;
  monthly = 12;
};
```

```bash
# Snapshot before a host update
zfs snapshot data/vms@pre-update-$(date +%Y%m%d)

# List snapshots
zfs list -t snapshot

# Roll back
zfs rollback data/vms@pre-update-20240101
```

- Wiki: https://wiki.nixos.org/wiki/ZFS

---

### microvm.nix (Alternative — Lightweight NixOS VMs)

For running NixOS VMs declaratively:
- GitHub: https://github.com/astro/microvm.nix

```nix
# flake.nix
microvm.nixosModules.microvm

# Guest VM definition
microvm.vms.customer1 = {
  pkgs = nixpkgs.legacyPackages.x86_64-linux;
  config = {
    microvm = {
      hypervisor = "qemu";
      mem = 4096;
      vcpu = 4;
      shares = [{
        source = "/data/customer1";
        mountPoint = "/data";
        tag = "customer1-data";
      }];
    };
  };
};
```

---

## Phase 6 — Hardware Repurposing & Local AI

**Goals covered:** Goal 7
**Estimated time:** Ongoing / long-term project

---

### Desktop as Primary AI Server (Ryzen 3900x + RTX 3070)

> Your RTX 3070 (8GB VRAM) is your most capable AI machine. It can run 7B–13B models at full speed via CUDA with no compromise. The 3900x (12c/24t) handles CPU offloading for larger models.

#### NVIDIA Driver Setup

```nix
# hosts/desktop/default.nix
{ config, pkgs, ... }: {
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    modesetting.enable = true;
    powerManagement.enable = false;
    open = false;          # use proprietary driver
    nvidiaSettings = true;
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
    ];
  };
}
```

- Wiki: https://wiki.nixos.org/wiki/Nvidia

#### Ollama with CUDA

```nix
# modules/ai.nix
{ config, lib, pkgs, ... }:
let cfg = config.homelab.ai;
in {
  options.homelab.ai.enable = lib.mkEnableOption "local AI server";

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      acceleration = "cuda";         # or "rocm" for AMD
      host = "0.0.0.0";              # listen on all interfaces
      port = 11434;
      environmentVariables = {
        OLLAMA_KEEP_ALIVE = "24h";   # keep models loaded in VRAM
        OLLAMA_NUM_PARALLEL = "2";
      };
    };

    networking.firewall.allowedTCPPorts = [ 11434 ];

    # Expose via Caddy on your Netbird VPN domain
    services.caddy.virtualHosts."ai.home.yourdomain.com".extraConfig = ''
      reverse_proxy localhost:11434
    '';
  };
}
```

```bash
# Pull models
ollama pull llama3.1:8b
ollama pull codestral:22b-v0.1-q4
ollama pull nomic-embed-text

# Test
ollama run llama3.1:8b "Hello from NixOS"
```

- Wiki: https://wiki.nixos.org/wiki/Ollama

#### Recommended Models for RTX 3070 (8GB VRAM)

| Model | VRAM | Use case |
|---|---|---|
| `llama3.1:8b` | ~5GB | General assistant, fast |
| `codestral:22b-v0.1-q4` | ~13GB (needs offload) | Code generation |
| `mistral-nemo:12b` | ~7GB | Good general assistant |
| `qwen2.5-coder:7b` | ~5GB | Code, fits fully in VRAM |
| `nomic-embed-text` | ~300MB | Embeddings for RAG |
| `deepseek-coder-v2:16b-lite-q4` | ~10GB | Code, with CPU offload |

#### Connect Neovim AI to Local Ollama

```bash
# Set in your shell profile (managed by Home Manager)
export AVANTE_API_ENDPOINT="http://ai.home.yourdomain.com:11434/v1"
export AVANTE_API_KEY="ollama"  # Ollama ignores the key but avante requires one
export AVANTE_MODEL="llama3.1:8b"
```

---

### PS4 as a Secondary AI Server

> **Realistic expectations:** PS4 Linux requires a jailbroken PS4 (firmware ≤9.00). The PS4 Pro's Polaris GPU has limited ROCm support. Expect CPU-only inference or small models. The desktop is far more capable.

**Steps:**
1. Jailbreak PS4 to firmware ≤9.00 (check: https://psxhax.com for current status)
2. Install PS4 Linux (custom kernel) — get Ubuntu/Debian working first
3. Install NixOS via the standard installer (nixos-anywhere can help once Linux is running)
4. Configure Ollama for CPU inference

```nix
# PS4 NixOS config — CPU-only inference
services.ollama = {
  enable = true;
  acceleration = null;     # no GPU acceleration — CPU only
  environmentVariables = {
    OLLAMA_NUM_THREAD = "6";    # PS4 has a Jaguar 8-core CPU
  };
};
```

**PS4 GPU (Radeon GCN):**
```nix
# Try ROCm — results vary significantly
hardware.opengl.extraPackages = with pkgs.rocmPackages; [
  clr
  rocminfo
];
services.ollama.acceleration = "rocm";
```

- NixOS ROCm Wiki: https://wiki.nixos.org/wiki/AMD_GPU

---

### Dual-Use Desktop: Workstation + AI Server

Run Ollama as a background service that doesn't interfere with desktop use. The GPU handles desktop compositing normally; Ollama uses remaining VRAM.

```nix
# Only load models when a request arrives (saves VRAM during desktop use)
services.ollama.environmentVariables = {
  OLLAMA_KEEP_ALIVE = "5m";    # unload models after 5 min of inactivity
};
```

---

## Quick Reference Commands

```bash
# Rebuild current machine from local config
sudo nixos-rebuild switch --flake .#hostname

# Rebuild with verbose output (useful for debugging)
sudo nixos-rebuild switch --flake .#hostname --show-trace

# Rebuild from GitHub directly (auto-update)
sudo nixos-rebuild switch --flake github:youruser/nixos-config#hostname

# Test a config change without making it the boot default
sudo nixos-rebuild test --flake .#hostname

# Install NixOS onto a new machine (nixos-anywhere)
nix run github:nix-community/nixos-anywhere -- --flake .#hostname root@192.168.1.100

# Deploy to all machines via Colmena
colmena apply

# Deploy to one machine
colmena apply --on homelab

# Update all flake inputs
nix flake update

# Update a single input
nix flake update nixpkgs

# Rollback to previous generation
sudo nixos-rebuild switch --rollback

# List all generations
sudo nix-env -p /nix/var/nix/profiles/system --list-generations

# Check what changed between generations
nvd diff /run/current-system $(ls -t /nix/var/nix/profiles/system-*link | head -2 | tail -1)

# Run garbage collection
sudo nix-collect-garbage -d         # delete ALL old generations (be careful)
sudo nix-collect-garbage --delete-older-than 30d

# Check disk usage of Nix store
du -sh /nix/store
nix path-info --all | sort -k2 -rh | head -20

# Encrypt a new secret (agenix)
agenix -e secrets/my-secret.age

# Build a custom installer ISO
nix run github:nix-community/nixos-generators -- -f iso -c ./installer.nix -o ./result
```

---

## Goal-to-Phase Mapping

| Goal | Description | Phase(s) |
|---|---|---|
| Goal 1 | Reproducible NixOS homelab config (Caddy, Immich, Nextcloud, Jellyfin, AdGuard, Netbird) | Phase 1 + 2 |
| Goal 2 | Portable Helix/Neovim dev setup, AI tools, keyboard shortcuts | Phase 4 |
| Goal 3 | Auto-update all machines when pushing to GitHub main | Phase 3 |
| Goal 4 | Bulk provision uninitialized machines from config | Phase 3 |
| Goal 5 | Best practices and scalable patterns | Phase 2 (ongoing) |
| Goal 6 | Customer VMs (ZimaOS), VFIO passthrough, update safety | Phase 5 |
| Goal 7 | Repurpose PS4 + desktop as AI servers, local Ollama | Phase 6 |

---

## Additional Tools & Resources

| Tool | URL | Purpose |
|---|---|---|
| nixos-anywhere | https://github.com/nix-community/nixos-anywhere | Remote NixOS installation |
| disko | https://github.com/nix-community/disko | Declarative disk partitioning |
| deploy-rs | https://github.com/serokell/deploy-rs | Push-based deployment |
| Colmena | https://github.com/zhaofengli/colmena | Fleet management |
| agenix | https://github.com/ryantm/agenix | Secrets management |
| sops-nix | https://github.com/Mic92/sops-nix | Alternative secrets management |
| nixvim | https://github.com/nix-community/nixvim | Declarative Neovim |
| home-manager | https://github.com/nix-community/home-manager | User environment management |
| nixos-hardware | https://github.com/NixOS/nixos-hardware | Hardware-specific configs |
| impermanence | https://github.com/nix-community/impermanence | Explicit state management |
| microvm.nix | https://github.com/astro/microvm.nix | Declarative NixOS VMs |
| nixos-generators | https://github.com/nix-community/nixos-generators | Build NixOS images (ISO, VM, etc) |
| Niri | https://github.com/YaLTeR/niri | Scrolling tiling Wayland compositor |
| avante.nvim | https://github.com/yetone/avante.nvim | AI coding assistant (Neovim) |
| codecompanion.nvim | https://github.com/olimorris/codecompanion.nvim | Alternative AI assistant (Neovim) |
| Netbird | https://netbird.io | WireGuard-based overlay VPN |

---

*Generated from the NixOS Ultimate Homelab Guide. Last updated 2026.*
*Primary resource channel: https://www.youtube.com/@vimjoyer*
