#' Source: https://github.com/seasmith/AlignAssign
capture_active <- function() {
  # Get context
  rstudioapi::getSourceEditorContext()
}

#' @input capture document_context from RStudio API
#'
#' Source: https://github.com/seasmith/AlignAssign
captureArea <- function(capture) {
  # Find range
  range_start <- capture$selection[[1L]]$range$start[[1L]]
  range_end <- capture$selection[[1L]]$range$end[[1L]]

  # Dump contents and use highlighted lines as names.
  contents <- capture$contents[range_start:range_end]
  names(contents) <- range_start:range_end
  return(contents)
}

#' Tidy ifelse statements
#'
#' Convert nested \code{ifelse()} statements to \code{case_when()}.
#'
#' @importFrom magrittr %>% extract2
#' @importFrom utils tail
#' @importFrom stringr str_split str_remove_all str_trim str_c str_remove regex
#' @importFrom dplyr pull mutate
#'
#' @export
nestedIfElseToCaseWhen <- function() {
  capture <- capture_active()
  area <- captureArea(capture)

  # Join all strings into one to make things simpler
  # if_else_string <- area %>%
      # trimws() %>%
      # paste(collapse = "")

  # Split up if-else statement into vector parts
  if_else_parts <-
      capture %>%
      extract2("selection") %>%
      extract2(1) %>%
      extract2("text") %>%
      str_split(pattern = ",") %>%
      extract2(1) %>%
      str_remove(regex("\\n")) %>%
      str_trim()

  # Save last element separately because odd number of elements
  ending_result <-
      if_else_parts %>%
      tail(1) %>%
      str_remove("\\)*$") %>%
      str_trim()
  rest_results <- if_else_parts[1:(length(if_else_parts) - 1)]

  # Put into two-column data frame for easier manipulation
  if_else_col <- rest_results %>%
      matrix(ncol = 2, byrow = TRUE) %>%
      as.data.frame()
  names(if_else_col) <- c("condition", "yes_test")

  # Remove `ifelse` from first column and slowly convert to case_when() syntax
  new_conditions <-
      if_else_col %>%
      mutate(condition = str_remove(condition, "ifelse\\(")) %>%
      mutate(new_arg = str_c(condition, " ~ ", yes_test, ",")) %>%
      mutate(new_arg = str_c("  ", new_arg)) %>%
      pull(new_arg)

  # Format everything to a vector
  ending_final <- paste(c("  TRUE", ending_result), collapse = " ~ ")
  final_work <- c("case_when(", new_conditions, ending_final, ")")

  # Return results
  contents <- paste(final_work, collapse = "\n")
  rstudioapi::modifyRange(
      location = capture[["selection"]][[1]][["range"]],
      text = contents,
      id = capture[["id"]])
}
