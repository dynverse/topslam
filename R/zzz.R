#' @importFrom glue glue
.onLoad <- function(libname, pkgname) {
  path <- find.package('topslam')
  if(!dir.exists(glue::glue("{path}/venv"))) {
    reinstall()
  }
}

#' @importFrom glue glue
reinstall <- function() {
  path <- find.package('topslam')
  system(glue::glue("bash {path}/make {path}/venv"))
}
