let
 pkgs = import (fetchTarball "https://github.com/rstats-on-nix/nixpkgs/archive/2025-07-02.tar.gz") {};
 
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

  buildInputs = [  rpkgs system_packages   ];
  
}
