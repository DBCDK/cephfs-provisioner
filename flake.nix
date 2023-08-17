{
  description = "dynamic ceph provisioner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.05";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }: let
    package = "cephfs-provisioner";
    provisionCmdPath = "usr/local/bin";
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      flake.overlays.default = final: prev: let
        python = final.python310;
      in {
        "${package}" = final.buildGoModule {
          version = "0.1";
          pname = package;
          src = ./.;
          vendorSha256 = "sha256-DD73LLQYR/DWolZZUeNO8c93Vnknbjgn5A1UUWs+b+Q=";

          buildInputs = [final.makeWrapper];
          propagatedBuildInputs = [python final.ceph];

          postPatch = let
            pyLibPath = "${final.ceph}/lib/${python.libPrefix}/site-packages";
          in ''
            set -e
            mkdir -p $out/${provisionCmdPath}
            cp cephfs_provisioner/cephfs_provisioner.py $out/${provisionCmdPath}/cephfs_provisioner
            patchShebangs $out/
            stat ${pyLibPath}
            wrapProgram "$out/${provisionCmdPath}/cephfs_provisioner" --set PYTHONPATH ${pyLibPath}
          '';
        };
      };
      systems = ["x86_64-linux"];

      perSystem = {
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
          ];
          config = {};
        };

        packages.default = pkgs.${package};

        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            go
            gopls
          ];
        };

        checks = self'.packages;
      };
    };
}
