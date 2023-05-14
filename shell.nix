let
  pkgs = import <nixpkgs> {};
  stdenv = pkgs.stdenv;

in stdenv.mkDerivation rec {
  name = "ruby-bepasty-client";

  buildInputs = with pkgs;[
    ruby
    git
    openssl
  ];

  shellHook = ''
    export GEM_HOME=$(pwd)/.gems
    export PATH="$GEM_HOME/bin:$PATH"
    export MANPATH="$(pwd)/man:$(man --path)"
    gem install bundler
    bundle install
  '';
}
