library(optparse)
library(digest)

option_list = list(
  make_option(c("-f", "--file"), type="character", default=NULL, 
              help="sample names file [default= %default]", metavar="character"),
  make_option(c("-p", "--script"), type="character", default=NULL, 
              help="path to script file [default= %default]", metavar="character"),
  make_option(c("-c", "--cpu"), type="numeric", default=NULL, 
              help="number of cpus per task [default= %default]", metavar="numeric"), 
  make_option(c("-m", "--mem"), type="character", default=NULL, 
              help="number of minimum amount of real memory [default= %default]", metavar="character"), 
  make_option(c("-t", "--time"), type="numeric", default=NULL, 
              help="time limit in minutes [default= %default]", metavar="numeric")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

if (is.null(opt$file)){
  print_help(opt_parser)
  stop("Input a sample names file.", call.=FALSE)
} else if (is.null(opt$script)){
  print_help(opt_parser)
  stop("Input a path to a script file.", call.=FALSE)
} else if (is.null(opt$cpu)) {
  print_help(opt_parser)
  stop("Input the number of cpus per task.", call.=FALSE)
} else if (is.null(opt$mem)) {
  print_help(opt_parser)
  stop("Input the number of minimum amount of real memory.", call.=FALSE)
} else if (is.null(opt$time)) {
  print_help(opt_parser)
  stop("time limit in minutes.", call.=FALSE)
}


df <- readLines(opt$file)
jobname <- paste0("tmp_", digest(Sys.time(), algo = "xxhash32"))

for (i in seq_along(df)) {
  #Checkpoint
  check1 <- file.exists(file.path("/projects/cangen/coliveir/scRNA_output/SeuratObjects/", df[i], paste0(df[i], ".rds")))
  
  if (check1 == F) {
    sink(paste0("/scratch2/coliveir/", jobname, "_", i, ".btc"))
    
    cat("#! /bin/bash -l", "\n")
    cat(paste0("#SBATCH --job-name ", paste0(jobname, "_", i)), "\n")
    cat(paste0("#SBATCH --error ", paste0("/scratch2/coliveir/", jobname, "_", i, ".err")), "\n")
    cat(paste0("#SBATCH --output ", paste0("/scratch2/coliveir/", jobname, "_", i, ".out"), "\n"))
    cat(paste0("#SBATCH --cpus-per-task=", opt$cpu), "\n")
    cat(paste0("#SBATCH --mem=", opt$mem), "\n")
    cat(paste0("#SBATCH --time=", opt$time), "\n")
    cat("\n")
    cat("export OMP_NUM_THREADS=$SLURM_CPUS_PER_TASK", "\n")
    cat("\n")
    cat(paste0("R --vanilla -f ", opt$script, " --args ", df[i]), "\n")
    cat("\n")
    cat("echo [$(date)] Starting execution of sample", "\n")
    
    sink()
    
    system(paste0("sbatch /scratch2/coliveir/", jobname, "_", i, ".btc"))
  } else {
    next()
  } 
}