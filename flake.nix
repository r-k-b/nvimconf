{
  description = "rkb's neovim configuration";
  # based on https://github.com/zmre/pwnvim

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = { allowUnfree = true; };
        };

        recursiveMerge = attrList:
          let
            f = attrPath:
              builtins.zipAttrsWith (n: values:
                if pkgs.lib.tail values == [ ] then
                  pkgs.lib.head values
                else if pkgs.lib.all pkgs.lib.isList values then
                  pkgs.lib.unique (pkgs.lib.concatLists values)
                else if pkgs.lib.all pkgs.lib.isAttrs values then
                  f (attrPath ++ [ n ]) values
                else
                  pkgs.lib.last values);
          in f [ ] attrList;

        dependencies = with pkgs;
          [
            #zsh # terminal requires it
          ];

        neovim-augmented = recursiveMerge [
          pkgs.neovim-unwrapped
          { buildInputs = dependencies; }
        ];

        nvimconf = pkgs.wrapNeovim neovim-augmented {
          viAlias = true;
          vimAlias = true;
          withNodeJs = false;
          withPython3 = false;
          withRuby = false;
          extraPython3Packages = false;
          extraMakeWrapperArgs =
            ''--prefix PATH : "${pkgs.lib.makeBinPath dependencies}"'';
          configure = {
            customRC = ''
              " show whitespace
              set list
              set listchars=tab:>-

              set relativenumber
              set number
            '';
            packages.myPlugins = with pkgs.vimPlugins; {
              start = with pkgs.vimPlugins; [
                editorconfig-vim
                vim-airline
                vim-better-whitespace
                vim-gitgutter
                vim-nix
              ];
            };
          };
        };

        nvimconfApp = flake-utils.lib.mkApp {
          drv = nvimconf;
          name = "nvimconf";
          exePath = "/bin/nvim";
        };
      in {
        packages.nvimconf = nvimconf;
        packages.default = nvimconf;
        apps.nvimconf = nvimconfApp;
        apps.default = nvimconfApp;
        devShell = pkgs.mkShell { buildInputs = [ nvimconf ] ++ dependencies; };
      });
}

