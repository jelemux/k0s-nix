{ lib, config, ... }: let
  inherit (lib) mkEnableOption mkOption optionalAttrs;
  inherit (lib.types) enum port submodule addCheck;
in {
  options = {

    enabled = mkEnableOption "Indicates if node-local load balancing should be used to access Kubernetes API servers from worker nodes. Default: `false`.";

    type = mkOption {
      type = enum [ "EnvoyProxy" ];
      default = "EnvoyProxy";
      description = ''
        The type of the node-local load balancer to deploy on worker nodes.
        Default: `EnvoyProxy`. (This is the only option for now.)
      '';
    };

    envoyProxy = optionalAttrs (config.enabled && config.type == "EnvoyProxy") (mkOption {
      type = submodule {
        options = {
          image = mkOption {
            type = addCheck (submodule (import ./image.nix)) (s: s != {});
            default = {
              image = "quay.io/k0sproject/envoy-distroless";
              version = "v1.30.2";
            };
          };
          imagePullPolicy = mkOption {
            type = enum [ "Always" "Never" "IfNotPresent" "" ];
            default = "";
          };
          apiServerBindPort = mkOption {
            type = port;
            default = 7443;
          };
          konnectivityServerBindPort = mkOption {
            type = port;
            default = 7132;
          };
        };
      };
      default = {};
      description = ''
        Configuration options related to the "EnvoyProxy" type of load balancing.
      '';
    });

  };
}