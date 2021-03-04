let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {
    config = {};
    overlays = [
      (import ./nix/overlay.nix)
    ];
  };
  profileEnv = pkgs.writeTextFile {
    name = "profile-env";
    destination = "/.profile";
    # This gets sourced by direnv. Set NIX_PATH, so `nix-shell` uses the same nixpkgs as here.
    text = ''
      export NIX_PATH=nixpkgs=${toString pkgs.path}
    '';
  };

  helmWithPlugins = pkgs.wrapHelm pkgs.kubernetes-helm {
    plugins = with pkgs.kubernetes-helmPlugins; [ helm-s3 helm-secrets helm-diff ];
  };

in {
  inherit pkgs profileEnv;

  env = pkgs.buildEnv{
    name = "wire-server-deploy";
    paths = with pkgs; [
      ansible_with_libs
      apacheHttpd
      awscli
      gnumake
      gnupg
      helmfile
      kubectl
      openssl
      moreutils
      pythonForAnsible
      rke
      skopeo
      sops
      terraform_0_13
      yq
    ] ++ [ profileEnv helmWithPlugins ];
  };
}
