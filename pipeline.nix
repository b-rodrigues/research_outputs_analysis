let
  default = import ./default.nix;
  defaultPkgs = default.pkgs;
  defaultShell = default.shell;
  defaultBuildInputs = defaultShell.buildInputs;
  defaultConfigurePhase = ''
    cp ${./_rixpress/default_libraries.R} libraries.R
    mkdir -p $out  
    mkdir -p .julia_depot  
    export JULIA_DEPOT_PATH=$PWD/.julia_depot  
    export HOME_PATH=$PWD
  '';
  
  # Function to create R derivations
  makeRDerivation = { name, buildInputs, configurePhase, buildPhase, src ? null }:
    defaultPkgs.stdenv.mkDerivation {
      inherit name src;
      dontUnpack = true;
      inherit buildInputs configurePhase buildPhase;
      installPhase = ''
        cp ${name} $out/
      '';
    };

  # Define all derivations
    luxembourg_works_raw = makeRDerivation {
    name = "luxembourg_works_raw";
    src = ./dataset/luxembourg_works.rds;
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      cp $src input_file
      Rscript -e "
        source('libraries.R')
        data <- do.call(readRDS, list('input_file'))
        saveRDS(data, 'luxembourg_works_raw')"
    '';
  };

  openalex_1 = makeRDerivation {
    name = "openalex_1";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        luxembourg_works_raw <- readRDS('${luxembourg_works_raw}/luxembourg_works_raw')
        openalex_1 <- luxembourg_works_raw %>% mutate(publication_year = year(publication_date), doi_missing = is.na(doi)) %>% filter(publication_year >= 2015)
        saveRDS(openalex_1, 'openalex_1')"
    '';
  };

  type_doi_missing = makeRDerivation {
    name = "type_doi_missing";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        openalex_1 <- readRDS('${openalex_1}/openalex_1')
        type_doi_missing <- openalex_1 %>% mutate(doi_missing = ifelse(doi_missing, 'Has_DOI', 'DOI_missing')) %>% tabyl(type, doi_missing) %>% mutate(Total = Has_DOI + DOI_missing) %>% rename(Type = type)
        saveRDS(type_doi_missing, 'type_doi_missing')"
    '';
  };

  dataset = makeRDerivation {
    name = "dataset";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        openalex_1 <- readRDS('${openalex_1}/openalex_1')
        dataset <- filter(openalex_1, type == 'article') %>% mutate(first_author_country = map(authorships, get_first_author_country), is_lu_first_author = map_lgl(first_author_country, function(x) {     (grepl('LU', x)) }), primary_domain_name = map_chr(topics, safe_get_domain_name), primary_subfield_name = map_chr(topics, safe_get_subfield_name))
        saveRDS(dataset, 'dataset')"
    '';
  };

  lu_first_authors = makeRDerivation {
    name = "lu_first_authors";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        dataset <- readRDS('${dataset}/dataset')
        lu_first_authors <- dataset %>% group_by(publication_year, is_lu_first_author) %>% summarise(total = n_distinct(doi), .groups = 'drop')
        saveRDS(lu_first_authors, 'lu_first_authors')"
    '';
  };

  primary_domain_lu = makeRDerivation {
    name = "primary_domain_lu";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        dataset <- readRDS('${dataset}/dataset')
        primary_domain_lu <- dataset %>% group_by(publication_year, primary_domain_name, is_lu_first_author) %>% summarise(total = n_distinct(doi), .groups = 'drop')
        saveRDS(primary_domain_lu, 'primary_domain_lu')"
    '';
  };

  primary_subfield_lu = makeRDerivation {
    name = "primary_subfield_lu";
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      Rscript -e "
        source('libraries.R')
        dataset <- readRDS('${dataset}/dataset')
        primary_subfield_lu <- tabyl(dataset, primary_subfield_name, is_lu_first_author)
        saveRDS(primary_subfield_lu, 'primary_subfield_lu')"
    '';
  };

  report = defaultPkgs.stdenv.mkDerivation {
    name = "report";
    src = defaultPkgs.lib.fileset.toSource {
      root = ./.;
      fileset = defaultPkgs.lib.fileset.unions [ ./report/report.qmd ];
    };
    buildInputs = defaultBuildInputs;
    configurePhase = defaultConfigurePhase;
    buildPhase = ''
      mkdir home
      export HOME=$PWD/home
      export RETICULATE_PYTHON=${defaultPkgs.python3}/bin/python


      quarto render report/report.qmd  --output-dir $out
    '';
  };

  # Generic default target that builds all derivations
  allDerivations = defaultPkgs.symlinkJoin {
    name = "all-derivations";
    paths = with builtins; attrValues { inherit luxembourg_works_raw openalex_1 type_doi_missing dataset lu_first_authors primary_domain_lu primary_subfield_lu report; };
  };

in
{
  inherit luxembourg_works_raw openalex_1 type_doi_missing dataset lu_first_authors primary_domain_lu primary_subfield_lu report;
  default = allDerivations;
}
