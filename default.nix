let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-07-07.tar.gz") {};
 
  rpkgs = builtins.attrValues {
    inherit (pkgs.rPackages) 
      R_utils
      archive
      crosstalk
      dplyr
      DT
      ggplot2
      httr
	    htmltools
      janitor
      jsonlite
      lubridate
      openalexR
      plotly
      purrr
      quarto
      readr
      readxl
      tarchetypes
      targets
      tidyjson
      tidyr
      tinytable
      xml2
      ;
  };

    rixpress = (pkgs.rPackages.buildRPackage {
      name = "rixpress";
      src = pkgs.fetchgit {
        url = "https://github.com/b-rodrigues/rixpress/";
        rev = "dfef00af24b43aabbcf26efe61b3fb72d4a89bd9";
        sha256 = "sha256-bTaSEQXjWO/F2riQK0lS3R6PNNyNpUcZPzp9qEVEA00=";
      };
      propagatedBuildInputs = builtins.attrValues {
        inherit (pkgs.rPackages) 
          igraph
          jsonlite
          processx;
      };
    });
  
  
  system_packages = builtins.attrValues {
    inherit (pkgs) 
      air-formatter
      glibcLocales
      glibcLocalesUtf8
      nix
      R
      typst
      quarto
      ;
  };
  
in

pkgs.mkShell {
  LOCALE_ARCHIVE = if pkgs.system == "x86_64-linux" then "${pkgs.glibcLocales}/lib/locale/locale-archive" else "";
  LANG = "en_US.UTF-8";
   LC_ALL = "en_US.UTF-8";
   LC_TIME = "en_US.UTF-8";
   LC_MONETARY = "en_US.UTF-8";
   LC_PAPER = "en_US.UTF-8";
   LC_MEASUREMENT = "en_US.UTF-8";

  buildInputs = [ rpkgs rixpress system_packages ];
  
}
