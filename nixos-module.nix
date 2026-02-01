{ self, config, lib, pkgs, ... }:
let
  cfg = config.services.cyan-skillfish-governor;
  renderedConfig = pkgs.writeText "cyan-skillfish-governor.toml" cfg.configText;
in
{
  options.services.cyan-skillfish-governor = {
    enable = lib.mkEnableOption "Cyan Skillfish GPU Governor";

    package = lib.mkOption {
      type = lib.types.package;
      default = self.packages.${pkgs.system}.default;
    };

    configText = lib.mkOption {
      type = lib.types.lines;
      default = builtins.readFile (cfg.package + "/share/cyan-skillfish-governor/default-config.toml");
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
