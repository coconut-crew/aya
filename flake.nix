{
  inputs = {
    roblox-development-flake.url = "github:nnullcolumn/roblox-development-flake";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      nixpkgs,
      roblox-development-flake,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      # super overkill since its just bash but whatever
      nnull_shell = pkgs.writeShellScriptBin "nnull-shell" ''
        bash
      '';

      nnull_packages = pkgs: [
        nnull_shell
        pkgs.codex # slop
        pkgs.fish # :3
      ];

      robloxShells = roblox-development-flake.devShells.${system};
    in
    {
      devShells.${system} = {
        default = robloxShells.default;
        simple = robloxShells.simple;
        fish = robloxShells.fish;

        nnull =
          (roblox-development-flake.lib.fhs {
            overrides = old: {
              targetPkgs = pkgs: nnull_packages (pkgs) ++ old.targetPkgs (pkgs);

              runScript = (old.runScript or "") + ''
                nnull-shell
              '';
            };
          }).env;
      };
    };
}
