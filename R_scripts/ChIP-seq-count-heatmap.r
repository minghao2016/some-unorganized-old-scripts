#07/19/13 by Ming Tang
# this R script demonstrates how to generate a heatmap using the count data from  ChIP-seq
# the count table was generated by bedtools genmoecov, a bam file that contains the mapped ( and unmapped) raw data
# define a set of genomic intervals( promoter regions, enhancer regions etc) in bed format that you want the bedtools to count.
# Homer and subread can do the same job.
# after get the count table, normalize the count to CPM (count per million reads), log2(x+1) transform the data
# total mapped reads can be obtained by samtools flagstat or HTSeq python package
# see my post here http://crazyhottommy.blogspot.com/2013/06/count-how-many-mapped-reads-in-bam-file.html
# heatmap.2 from gplots is used to generate the heatmap
# often, you want to get the feature names that are clustered into the same group.hclust and cutree are used to serve this purpose.
# watch youtube here https://www.youtube.com/watch?v=PArRvqLUP6o
# and here https://www.youtube.com/watch?v=wQhVWUcXM0A
# https://www.youtube.com/watch?v=nIsLDtXlalo
=======
# https://www.youtube.com/watch?v=nIsLDtXlalo
# understand what is k-means clustering and hierarchical clustering

library(gplots)
getwd()
setwd("/home/tommy/CHIA_PET/TSS_-3kb_+1kb")
ls() # check what variables are there in the current name space.
rm(list=ls()) # drop all the variables 


d<- read.table("heatmaps.txt", header=T) # read the table into a dataframe 
head(d)
d$HIF1<- log2((d$HIF1+1)*1000000/4546673) # normalize and log transform the data
=======
d$HIF1<- log2((d$HIF1+1)*1000000/4546673) # normalize to the library size (samtools) and log transform the data
d$Jund<- log2((d$Jund+1)*1000000/13689672)
d$Cmyc<- log2((d$Cmyc+1)*1000000/46578824)
d$Max<- log2((d$Max+1)*1000000/9641493)
d$CTCF<- log2((d$CTCF+1)*1000000/20769652)
head(d)
summary(d)
m<- as.matrix(d[,2:6]) # heatmap works with matrix object
head(m)
rownames(m)<- d$HRE # add feature names to the matrix 
head(m)
summary(m)
# you can do some clean up at this step, get rid of the outliers etc.
# histogram to exam the data.  use subset,

png(filename = "Rheatmap.png") #save the heatmap to a png or a pdf by pdf(filename=...)
hmcols<- colorRampPalette(c("green","green4","red","red4","yellow"))(256)
heatmap.2(m,col=hmcols,trace="none",Colv=FALSE, dendrogram = "row",density.info="none")
dev.off()
#http://hosho.ees.hokudai.ac.jp/~kubo/Rdoc/library/gplots/html/heatmap.2.html
#heatmap.2 performs clustering using the hclustfun and distfun parameters.
#This defaults to complete linkage clustering, using a euclidean distance measure.
#The dendrogram is then reordered using the row/column means. You can control this by
#specifying different functions to hclustfun or distfun. For example to use the Manhattan
#distance rather than the euclidiean distance you would do:
#heatmap.2(x,...,distfun=function (y) dist(y,method = "manhattan") )
#check out ?dist and ?hclust.

# to get the the matrix after clustering
hm<- heatmap.2(m)

names(hm)
#return the maxtrix returned after clustering as in the heatmap
m.afterclust<- m[rev(hm$rowInd),rev(hm$colInd)]


# to extract subgroups that are clustered together
# rowDendrogram is a list object 

labels(hm$rowDendrogram[[1]])
lables(hm$rowDendrogram[[2]][[2]])
#Separating clusters

#convert the rowDendrogram to a hclust object
hc<- as.hclust(hm$rowDendrogram)

names(hc)


png("dendogram3.png")
plot(hc)  # rotate the dendrogram 90 degree, it is the same as in the heatmap

rect.hclust(hc,h=8)

dev.off()

ct<- cutree(hc,h=8)

# get the members of each subgroup in the order of the cluster(left--->right), the row order will
# be reversed compared to the heatmap.

ct[hc$order]

table(ct)

# get the matrix after clustering in the order of the heatmap (up--->down)

tableclustn<-  data.frame(m.afterclust, rev(ct[hc$order]))
head(tableclustn)
write.table(tableclustn, file="tableclustn.xls", row.names=T, sep="\t")


# remake the heatmap adding the RowSide bar based on the subgroups

png("Rheatmap4.png")
mycolhc<- sample(rainbow(256))
mycolhc<-mycolhc[as.vector(ct)]
rowDend<- as.dendrogram(hc)

heatmap.2(m, Rowv=rowDend, Colv = FALSE, dendrogram = "row", col=hmcols, RowSideColors=mycolhc,trace="none",density.info="none")

dev.off()









#############################################################################
#If we'd like to separate out the clusters, I'm not sure of the best approach
# One way is to use hclust and cutree, which allows you to specify k, the number
#of clusters you want. Don't forget that hclust requires a distance matrix as input.
hc.rows<- hclust(dist(m))
# compute the distance with functin dist and do a hierachical cluster by hclust

names(hc.rows)
hc.rows$labels  #the original label from the maxtrix m
hc.rows$order
hc.rows$labels[hc.rows$order]  #print the row labels in the order they appear in the tree

plot(hc.rows) # plot the dendogram 

heatmap.2(m[cutree(hc.rows,k=3)==3,])
heatmap.2(m[cutree(hc.rows,k=3)==2,])
heatmap.2(m[cutree(hc.rows,k=5)==5,])
heatmap.2(m[cutree(hc.rows,k=5)==4,])
heatmap.2(m[cutree(hc.rows,k=5)==3,])
heatmap.2(m[cutree(hc.rows,k=5)==2,])
heatmap.2(m[cutree(hc.rows,k=6)==6,])

heatmap.2(m[cutree(hc.rows,k=4)==1,])

rect.hclust(hc.rows, h=10) # a rectangle that makes the edge of each group visiable
# if set the height=10, 6 subgroups will be generated.
cutree(hc.rows,h=10)

ct<- cutree(hc.rows,k=6)
#get the members' names of each clusters

head(ct)

table(ct)

sort(ct)


split(names(ct),ct)

mycolhc<- sample(rainbow(256))
mycolhc<-mycolhc[as.vector(ct)]
rowDend<- as.dendrogram(hc.rows)


heatmap.2(m, Rowv=rowDend, Colv = FALSE, dendrogram = "row", col=hmcols, RowSideColors=mycolhc,trace="none")
          



tableclustn<-  data.frame(m.afterclust, rev(ct[hc$order]))
head(tableclustn)
write.table(tableclustn, file="tableclustn.xls", row.names=T, sep="\t")

#mds plot Multidimensional Scaling

distance<- dist(m)


mds<- cmdscale(distance)

plot(mds)

#PCA analysis
#watch this to understand PCA
#https://www.youtube.com/watch?v=9DPiXrN2pEg
prcomp(m)

plot(prcomp(m))
summary(prcomp(m,scale=TRUE))
biplot(prcomp(m,scale=TRUE))
#####################################################################
