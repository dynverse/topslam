#' @importFrom glue glue
.onLoad <- function(libname, pkgname) {
  if(!dir.exists(glue::glue("bash {find.package('topslam')}/venv"))) {
    reinstall()
  }
}

#' Reinstalling topslam
#'
#' @importFrom glue glue
#' @export
reinstall <- function() {
  system(glue::glue("bash {find.package('topslam')}/make {find.package('topslam')}/venv"))
}
