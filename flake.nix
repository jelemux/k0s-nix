{
  description = "k0s - The Zero Friction Kubernetes for NixOS";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

  outputs = { nixpkgs, ... }:
    let

      genPackages = pkgs: rec {
        inherit (pkgs.callPackage ./k0s/default.nix {})
          k0s_1_27
          k0s_1_28
          k0s_1_30
          k0s_1_31
          k0s_1_32;
        k0s = k0s_1_32;
      };

    in
    rec {
      packages =
        let
          lib = nixpkgs.lib;
          allSystems = [ "armv7l-linux" "aarch64-linux" "x86_64-linux" ];
          forAllSystems = lib.genAttrs allSystems;
        in
          forAllSystems (system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
            in genPackages pkgs
          );

      overlays.default = final: prev: genPackages prev;

      nixosConfigurations = {
        test = nixpkgs.lib.nixosSystem {
          modules = [
            {
              nixpkgs.system = "x86_64-linux";
              nixpkgs.pkgs = import nixpkgs {
                system = "x86_64-linux";
                overlays = [
                  overlays.default
                ];
              };
            }
            ./nixos/k0s.nix
            ({ ... }: {
              boot.isContainer = true;

              services.k0s = {
                enable = true;

                role = "controller";

                # The first controller to bring up does not have a join token,
                # it has to be flagged with "isLeader".
                # isLeader = true;

                spec.api.address = "192.0.2.1";
                spec.api.sans = [
                  "192.0.2.1"
                  "192.0.2.2"
                ];

                # Test non-default options:
                #
                # spec.network.provider = "calico";
                # spec.network.calico.mode = "bird";
                # spec.network.dualStack.enabled = true;
                # spec.network.dualStack.IPv6podCIDR = "fd00::/108";
                # spec.network.dualStack.IPv6serviceCIDR = "fd01::/108";
                # spec.network.controlPlaneLoadBalancing.enabled = true;
                # spec.network.nodeLocalLoadBalancing.enabled = true;
                # spec.storage.type = "kine";
              };

              system.stateVersion = "24.05";
            })
          ];
        };
      };

      nixosModules.default = import ./nixos/k0s.nix;
  };
}
