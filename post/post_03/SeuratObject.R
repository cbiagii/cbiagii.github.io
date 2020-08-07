#!/usr/bin/env Rscript
arguments = commandArgs(trailingOnly=TRUE)

options(future.globals.maxSize = 20 * 1024 ^ 3)
plan("multiprocess", workers = 6)

sample <- as.character(arguments)


# Loading packages
library(Seurat)
library(future)

# Check if the input is a csv file or a 10x directory
test <- dir.exists(file.path("/path/to/datasets", sample))
if (test) {
  data <- CreateSeuratObject(counts = Read10X(data.dir = file.path("/path/to/datasets", sample)),
                             project = sample,
                             min.cells = 3,
                             min.features = 200)
} else {
  tmp <- list.files("/path/to/datasets", full.names = T)
  data <- CreateSeuratObject(counts = read.table(grep(sample, tmp, value = T), header = T, row.names = 1),
                             project = sample,
                             min.cells = 3,
                             min.features = 200)
}


s.genes <- cc.genes$s.genes
g2m.genes <- cc.genes$g2m.genes


dir.create(file.path("/path/to/output", sample))


data[["percent.mt"]] <- PercentageFeatureSet(data, pattern = "^MT-")
data <- subset(data, subset = nFeature_RNA < 3000 & percent.mt < 10)

data <- NormalizeData(data, verbose = F)

data <- FindVariableFeatures(data, verbose = F)

data <- CellCycleScoring(data, s.features = s.genes, g2m.features = g2m.genes, set.ident = TRUE)

data <- ScaleData(data, vars.to.regress = c("nCount_RNA", "percent.mt", "S.Score", "G2M.Score"))

data <- RunPCA(data, verbose = F)

data <- FindNeighbors(data)
data <- FindClusters(data)

data <- RunTSNE(data, perplexity = 30, dims = 1:30)
data <- RunUMAP(data, dims = 1:30)

# Save seurat object
saveRDS(data, file = file.path("/path/to/output", sample, paste0(sample, ".rds")))