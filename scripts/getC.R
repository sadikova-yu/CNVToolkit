args <- commandArgs()
inputFile <-args[6];
D <- as.numeric(scan(inputFile, what="", sep="\n", quiet=TRUE))
C=round(mean(D))
D2=D[D<=C]
E=1-(length(D2)-sum(D2)/C)/length(D)
cat(C,"\n")
