{
  description = "dynamic ceph provisioner";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {
    self,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = ["x86_64-linux"];

      perSystem = {
        self',
        inputs',
        pkgs,
        ...
      }: let
        package = "cephfs-provisioner";
        python = pkgs.python39;
        provisionCmdPath = "usr/local/bin";
      in {
        packages = {
          default = self'.packages."${package}";

          "${package}" = pkgs.buildGoModule {
            version = "0.1";
            pname = package;
            src = ./.;
            vendorSha256 = "sha256-DD73LLQYR/DWolZZUeNO8c93Vnknbjgn5A1UUWs+b+Q=";

            buildInputs = [ pkgs.makeWrapper ];
            propagatedBuildInputs = [ python pkgs.ceph ];

            postPatch = let
              pyLibPath = "${pkgs.ceph}/lib/${python.libPrefix}/site-packages";
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
