#' @title Export Objects to the Slaves
#'
#' @description
#' Objects are saved in subdirectory \dQuote{exports} of the
#' \dQuote{file.dir} of \code{reg}.
#' They are automatically loaded and placed in the global environment
#' each time the registry is loaded or a job collection is executed.
#'
#' @param export [\code{list}]\cr
#'  Named list of objects to export.
#' @param unexport [\code{character}]\cr
#'  Vector of object names to unexport.
#' @template reg
#' @return [\code{data.table}] with name and uri to the exported objects.
#' @export
#' @examples
#' \dontshow{ batchtools:::example_push_temp(1) }
#' tmp = makeRegistry(file.dir = NA, make.default = FALSE)
#'
#' # list exports
#' exports = batchExport(reg = tmp)
#' print(exports)
#'
#' # add a job and required exports
#' batchMap(function(x) x^2 + y + z, x = 1:3, reg = tmp)
#' exports = batchExport(export = list(y = 99, z = 1), reg = tmp)
#' print(exports)
#'
#' submitJobs(reg = tmp)
#' waitForJobs(reg = tmp)
#' stopifnot(loadResult(1, reg = tmp) == 101)
#'
#' # Un-export z
#' exports = batchExport(unexport = "z", reg = tmp)
#' print(exports)
batchExport = function(export = list(), unexport = character(0L), reg = getDefaultRegistry()) {
  assertRegistry(reg, writeable = (length(export) > 0L || length(unexport) > 0L))
  assertList(export, names = "named")
  assertCharacter(unexport, any.missing = FALSE, min.chars = 1L)

  path = fs::path(reg$file.dir, "exports")

  if (length(export) > 0L) {
    nn = names(export)
    fn = fs::path(path, mangle(nn))
    found = fs::file_exists(fn)
    if (any(!found))
      info("Exporting new objects: '%s' ...", stri_flatten(nn[!found], "','"))
    if (any(found))
      info("Overwriting previously exported object: '%s'", stri_flatten(nn[found], "','"))
    Map(writeRDS, object = export, file = fn, compress = reg$compress)
  }

  if (length(unexport) > 0L) {
    fn = fs::path(path, mangle(unexport))
    found = fs::file_exists(fn)
    if (any(found))
      info("Un-exporting exported objects: '%s' ...", stri_flatten(unexport[found], "','"))
    file_remove(fn[found])
  }

  fns = list.files(path, pattern = "\\.rds")
  invisible(data.table(name = unmangle(fns), uri = fs::path(path, fns)))
}
