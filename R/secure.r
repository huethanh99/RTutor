secure.base.env = function(ps=get.ps()) {
  env = new.env(parent=globalenv())
  env$get.ps = function(...) {
    cat("\ninner.get.ps")
    ps
  }
  env
}

# Run check.chunk within RAppArmor eval.secure
secure.check.chunk = function(chunk.ind, verbose=FALSE,stud.code=ps$cdt$stud.code[[chunk.ind]], stud.env=make.chunk.stud.env(chunk.ind, ps), expect.change = FALSE, store.output=TRUE, noeval = isTRUE(ps$noeval), precomp=isTRUE(ps$precomp), ..., ps = get.ps(), secure=!TRUE) {

  restore.point("secure.check.chunk")
  
  
  
  ck = ps$cdt[chunk.ind,]
  chunk.name = ck$chunk.name

  ps$cdt$old.stud.code[chunk.ind] = stud.code
  ps$cdt$is.solved[chunk.ind] = FALSE
  
  ps$ex.ind = ck$ex.ind
  ps$chunk.ind = chunk.ind
  ps$chunk.name = chunk.name

  if (verbose)
    display("securely check chunk ", chunk.name," ...")

  ps$failure.message  = "No failure message recorded"
  ps$warning.messages = list()
  ps$check.date = Sys.time()

  has.error = FALSE
  ps$stud.expr.li = NULL
  if (verbose) {
    display("parse stud.code...")
  }

  if (!is.false(ps$catch.errors)) {
    tryCatch( ps$stud.expr.li <- base::parse(text=stud.code, srcfile=NULL),
              error = function(e) {
                ps$failure.message=paste0("parser error: ",geterrmessage())
                has.error <<- TRUE
              })
  } else {
    ps$stud.expr.li <- base::parse(text=stud.code, srcfile=NULL)
  }
  if (has.error)
    return(FALSE)


  if (isTRUE(ps$check.whitelist)) {
    if (verbose)
      display("check whitelist")
    res = rtutor.check.whitelist(ps$stud.expr.li,ps=ps)
    if (!res$ok) {
      ps$failure.message=paste0("security error: ",res$msg)
      return(FALSE)
    }
  }

  ps$stud.env = stud.env
  ps$cdt$stud.env[[chunk.ind]] = stud.env

  ps$stud.seed = as.integer(Sys.time())
  set.seed(ps$stud.seed)

  
  if (!secure)
    ps = as.environment(as.list(ps))
  
  env = secure.base.env(ps=ps)
  
  call = quote(
    inner.secure.check.chunk(chunk.ind=chunk.ind, verbose=verbose,stud.code=stud.code,  noeval = noeval, ps=ps, ...)
  )
  
  ps$in.secure.eval = TRUE
  if (!secure) {
    res = base::eval(call)
  } else {
    res = RTutor::rtutor.eval.secure(call, ps=ps)
  }
  
  fields = res$ps.fields
  ps$failure.message = as.character(fields$failure.message)
  ps$success.message = as.character(fields$ps$success.message)
  ps$success.log = sapply(fields$success.log, as.character)

  ps$e.ind = as.integer(fields$e.ind)
  ps$tdt.ind = as.integer(fields$tdt.ind)
  
  ps$cdt$is.solved[[chunk.ind]] = isTRUE(res$ok)
  ck = ps$cdt[chunk.ind,]
  
  if (!is.na(ck$award.name)) {
    give.award(ck$award.name, ps=ps)
    if (isTRUE(ps$is.shiny))
      show.shiny.award(ck$award.name)
  }
  
  if (isTRUE(ps$should.log)) {
    log.event(type="check_chunk",chunk=chunk.ind, ex=ck$ex.ind,e.ind=0,code=stud.code, ok=FALSE,message=ps$failure.message)
    update.ups.chunk.check(passed=res$ok,chunk.ind=chunk.ind, save=TRUE, ps=ps)
  }
  return(res$ok)
}


# The eval part of secure.check chunk
# will be called with eval.secure
inner.secure.check.chunk = function(chunk.ind,ps=get.ps(), verbose=FALSE,stud.code=ps$cdt$stud.code[[chunk.ind]], noeval = isTRUE(ps$noeval), precomp=isTRUE(ps$precomp)) {
  restore.point("inner.secure.check.chunk")

  stud.env = ps$stud.env
  ck = ps$cdt[chunk.ind,]

  #stop("analyse below")
  test.li = ck$test.expr[[1]]

  if (verbose)
    display("inner.secure.check.chunk ", chunk.name," ...")


  if (verbose) {
    display("eval stud.code...")
  }
  ps$e.ind = 0
  has.error = FALSE

  # run student code in stud.env
  if (!isTRUE(ps$noeval)) {
    has.error = !stepwise.eval.stud.expr(stud.expr=ps$stud.expr.li,stud.env=stud.env, store.output=FALSE)
    if (has.error) {
      return(inner.secure.check.chunk.return(FALSE))
    }
  }

  had.warning = FALSE
  if (verbose) {
    display("run tests...")
  }

  ps$success.log = ps$test.log = NULL
  e.ind = 1

  tdt.ind = which(ps$tdt$chunk.ps.ind == chunk.ind)[1]-1

  # Turn graphics device off

  if (isTRUE(ps$use.null.device)) {
    try(png("NUL"), silent=TRUE)
    on.exit(try(dev.off(), silent=TRUE),add = TRUE)
  }
  # Back to normal graphics device


  for (e.ind in seq_along(ck$e.li[[1]])) {
    ps$e.ind = e.ind
    tests = ck$test.expr[[1]][[e.ind]]
    test.ind = 1
    for (test.ind in seq_along(tests)){
      tdt.ind = tdt.ind +1
      ps$tdt.ind = tdt.ind
      test = tests[[test.ind]]
      ps$success.message = NULL
       if (verbose) {
        display("  Test #", test.ind, ": ",deparse1(test))
      }
      ret = eval(test,ps$ps.basenv)
      if (ret==FALSE) {
        return(inner.secure.check.chunk.return(FALSE))
      } else if (ret=="warning") {
        had.warning = TRUE
      } else {
        if (!is.null(ps$success.message)) {
          ps$success.log = c(ps$success.log,ps$success.message)
        }
      }
    }
  }

  if (had.warning) {
    return(inner.secure.check.chunk.return("warning"))
  } else {
    return(inner.secure.check.chunk.return(TRUE))
  }
}

inner.secure.check.chunk.return = function(ok, ps = get.ps()) {
  list(ok=ok,
    ps.fields = list(
      success.message=ps$success.message, failure.message=ps$failure.message, success.log=ps$success.log, e.ind = ps$e.ind, tdt.ind = ps$tdt.ind
    )
  )
}


rtutor.eval.secure = function(..., timeout = ps$secure.eval.timeout, profile=ps$secure.eval.profile, ps=get.ps()) {
   if (!RAppArmor::aa_is_enabled())
    stop("AppArmor is not enabled.")

  RAppArrmor::eval.secure(..., timeout=timeout, profile=profile)
}
