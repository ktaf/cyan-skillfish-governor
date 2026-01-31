{ config, lib, pkgs, ... }:
let
  cfg = config.services.cyan-skillfish-governor;
  renderedConfig = pkgs.writeText "cyan-skillfish-governor.toml" cfg.configText;
in
{
  options.services.cyan-skillfish-governor = {
    enable = lib.mkEnableOption "Cyan Skillfish GPU Governor";

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.cyan-skillfish-governor;
    };

    configText = lib.mkOption {
      type = lib.types.lines;
      default = ''
        # us
        [timing.intervals]
        sample = 2000
        adjust = 20_000
        finetune = 1_000_000_000

        # MHz/ms
        [timing.ramp-rates]
        normal = 1
        burst = 200

        # number of samples
        [timing]
        burst-samples = 48

        # MHz
        [frequency-thresholds]
        adjust = 100
        finetune = 10

        [load-target]
        upper = 0.95
        lower = 0.7

        [[safe-points]]
        frequency = 350 # MHz
        voltage = 700 # mV

        [[safe-points]]
        frequency = 2000
        voltage = 1000
      '';
      description = "Written to /etc/cyan-skillfish-governor/config.toml";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.etc."cyan-skillfish-governor/config.toml".source = renderedConfig;

    systemd.services.cyan-skillfish-governor = {
      description = "Cyan Skillfish GPU Governor";
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/cyan-skillfish-governor /etc/cyan-skillfish-governor/config.toml";
        Restart = "on-failure";
        RestartSec = 5;
        NoNewPrivileges = true;
        PrivateTmp = true;
      };
    };
  };
}
