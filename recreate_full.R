#!/home/lain/R/bin/Rscript


args <- batch::parseCommandArgs(evaluate=FALSE)


if (!is.null(args$original)) {
    print("Used original rdata")
    file.remove("./data/test.rdata")
    file.copy("./data/original.rdata", "./data/test.rdata")
    args$input <- "test.rdata"
}

load(paste0("./data/", args$input), rdata <- new.env())

FROM_XCMS <- "md5sumList" %in% names(rdata)

if (FROM_XCMS) {
    print("from xcms")
    md5sumList <- rdata$md5sumList
    xdata <- rdata$xdata
    sampleNamesList <- rdata$sampleNamesList
    zipfile <- rdata$zipfile
} else {
    listOFlistArguments <- rdata$listOFlistArguments
    diffrep <- rdata$diffrep
    variableMetadata <- rdata$variableMetadata
    xa <- rdata$xa
}

singles <- list.files("./data/")
if (is.null(args$begin_with) || args$begin_with == "") {
    singles <- singles[grepl(".*\\.mzML", singles)]
} else {
    singles <- singles[grepl(paste0("^", args$begin_with, ".*"), singles)]
}
singlefile <- list()
for (single in singles) {
    singlefile[single] <- normalizePath(paste0("./data/", single))
}
print(singlefile)
zipfile <- NULL

file.remove(paste0("./data/", args$output))
if (FROM_XCMS) {
    save(
        md5sumList,
        xdata,
        sampleNamesList,
        zipfile,
        singlefile,
        file=paste0("./data/", args$output)
        ,version=2
    )
} else {
    save(
        zipfile,
        listOFlistArguments,
        diffrep,
        variableMetadata,
        xa,
        singlefile,
        file=paste0("./data/", args$output)
        ,version=2
    )
}