#' Run topslam
#'
#' @param counts the counts
#' @param start_cell_id the names of starting cells
#' @param n_components the number of components
#' @param n_neighbors the number of neighbors
#' @param linear_dims ?
#' @param max_iters the number of iterations to optimize over
#' @param dimreds the dimensionality reductions to use
#'
#' @importFrom methods formalArgs
#' @importFrom utils write.table read.csv
#' @importFrom jsonlite toJSON
#' @export
topslam <- function(counts,
                    start_cell_id,
                    n_components = 2,
                    n_neighbors = 10,
                    linear_dims = 0,
                    max_iters = 200,
                    dimreds = c("t-SNE", "PCA", "Spectral", "Isomap", "ICA")) {
  # python counts from 0, R from 1
  start_cell_id <- which(rownames(counts) %in% start_cell_id) - 1

  # create a temporary folder
  temp_folder <- tempfile()
  dir.create(temp_folder, recursive = TRUE)

  tryCatch({
    # write expression data
    expr <- as.data.frame(log2(counts+1))
    utils::write.table(expr, paste0(temp_folder, "/counts.tsv"), sep="\t")

    # write params to json
    copy_args <- setdiff(methods::formalArgs(topslam), c("counts"))
    params <- as.list(environment())[copy_args]
    write(jsonlite::toJSON(params, auto_unbox = TRUE), paste0(temp_folder, "/params.json"))

    # execute topslam
    output <- system2(
      "/bin/bash",
      args = c(
        "-c",
        shQuote(glue::glue(
          "cd {find.package('topslam')}/venv",
          "source bin/activate",
          "python {find.package('topslam')}/wrapper.py {temp_folder}",
          .sep = ";"))
      ), stdout = TRUE, stderr = TRUE
    )

    # read output
    wad_grid <- utils::read.csv(paste0(temp_folder, "/wad_grid.csv"))
    wad_energy <- utils::read.csv(paste0(temp_folder, "/wad_energy.csv"))
    space <- utils::read.csv(paste0(temp_folder, "/space.csv"))
    pseudotime <- utils::read.csv(paste0(temp_folder, "/pseudotime.csv"))
  }, finally = {
    # remove temporary output
    unlink(temp_folder, recursive = TRUE)
  })

  # return output
  list(
    wad_grid = wad_grid,
    wad_energy = wad_energy,
    space = space,
    pseudotime = pseudotime
  )
}