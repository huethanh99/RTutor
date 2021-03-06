% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tests_for_ps.r
\name{check.call}
\alias{check.call}
\title{Checks whether the user makes a particular function call in his code or call a particular R statement}
\usage{
check.call(call, check.arg.by.value = TRUE, allow.extra.arg = FALSE,
  ignore.arg = NULL, success.message = NULL, failure.message = NULL,
  no.command.failure.message = NULL, ok.if.same.val = NA,
  s3.method = NULL, ps = get.ps(), stud.env = ps$stud.env,
  part = ps$part, stud.expr.li = ps$stud.expr.li, verbose = FALSE,
  noeval = isTRUE(ps$noeval), hint.on.fail = isTRUE(ps$rps$hint.on.fail),
  check.cols = NULL, sort.cols = NULL, is.ggplot = FALSE, ...)
}
\arguments{
\item{call}{the correct function call that shall be checked (not a quoted call)}

\item{check.arg.by.value}{if TRUE (default) check whether students arguments have the same value than in given call, even if their unevaluted representation looks different}

\item{allow.extra.arg}{if TRUE (not default) the student is allowed to supply additional arguments to the call that were not in the solution. Useful, e.g. if the student shall plot something and is allowed to customize her plot with additional arguments.}

\item{ignore.arg}{a vector of argument names that will be ignored when checking correctness}

\item{ok.if.same.val}{if TRUE (default) the call will be considered as correct, if it yields the same resulting value as the solution, even if its arguments differ.}

\item{hint.on.fail}{Shall automatically be a hint shown if a test fails. By default FALSE, i.e. student has to type \code{hint()}. Yet, default can be overwritten in call to \code{create.ps}.}

\item{check.cols}{only relevant if a data frame (or tibble) is computed. An optional character vector of column names. If provided only check whether those columns are correctly computed but ignore other columns. Only works if \code{compare.vals = TRUE} (default).}

\item{sort.cols}{only relevant if a data frame (or tibble) is computed. An optional character vector of column names. If provided sort the sample solution and student's solution by these columns before comparing. This means that also solutions that are originally sorted in a different fashion are accepted. Useful in combination with \code{check.cols}.}
}
\description{
Checks whether the user makes a particular function call in his code or call a particular R statement
}
