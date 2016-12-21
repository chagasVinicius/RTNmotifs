
################################################################################
##########################    plot dual regulons    ############################
################################################################################

#' Plot shared target clouds between dual regulons.
#'
#' This function plots the shared target clouds between a regulon pair.
#'
#' @param object A processed object of class \linkS4class{MBR} evaluated by the method \code{\link[RTNmotifs:mbr.association]{mbr.association}}.
#' @param names.motifs A vector with 'dual regulon' indentifiers from the 'motifsInformation' table.
#' @param filepath A character string indicating the file path where the plot should be saved.
#' @param alpha  The alpha transparency, a number in [0,1].
#' @param lncols A vector of length 2 indicating the colors of the negative and positive target clouds, respectively.
#' @param lwd  Line width, a decimal value (between 0 and 1).
#' @param estimator A character string indicating the association metric. One of "spearman" (default), "kendall", or "pearson", can be abbreviated.
#' @return A plot with the shared target clouds between dual regulons.
#' @examples
#' data("dt4rtn", package = "RTN")
#' gexp <- dt4rtn$gexp
#' annot <- dt4rtn$gexpIDs
#' tfs1 <- dt4rtn$tfs[c("IRF8","IRF1","PRDM1","AFF3","E2F3")]
#' tfs2 <- dt4rtn$tfs[c("HCLS1","STAT4","STAT1","LMO4","ZNF552")]
#' ##---mbr.preprocess
#' rmbr <- mbr.preprocess(gexp=gexp, regulatoryElements1 = tfs1, regulatoryElements2=tfs2, gexpIDs=annot)
#' ##---mbr.permutation
#' rmbr <- mbr.permutation(rmbr, nPermutations=10)
#' ##---mbr.bootstrap
#' rmbr <- mbr.bootstrap(rmbr, nBootstrap=10)
#' ##---mbr.dpi.filter
#' rmbr <- mbr.dpi.filter(rmbr)
#' ##---mbr.association
#' rmbr <- mbr.association(rmbr, prob=0.75)
#' ##---mbr.duals
#' rmbr <- mbr.duals(rmbr)
#' ##---
#' duals <- rownames(rmbr@results$motifsInformation)[1]
#' mbr.plot.duals(rmbr, names.motifs=duals)
#'
#' @import graphics
#' @importFrom grDevices adjustcolor dev.off pdf colorRampPalette
#' @importFrom graphics abline axis par plot.new plot.window points title legend
#' @export

##------------------------------------------------------------------------------
mbr.plot.duals <- function(object, names.motifs = NULL, filepath=NULL, alpha=0.80,lncols=c("darkgreen","darkorange3"), lwd=0.70, estimator="spearman")
{
    ##----check object class
    mbr.checks(name="object", para=object)
    mbr.checks(name="estimator", para=estimator)

    rtni <- .merge.tnis(object)
    estimator <- rtni@para$perm$estimator
    motifstb <- object@results$motifsInformation
    motifstb <- .namesMotifs.check(motifstb, names.motifs)

    res <- apply(motifstb, 1, function (mtfs)
        {
            mtfs <- as.character(mtfs)
            reg1 <- mtfs[1]
            reg2 <- mtfs[2]
            rval <- as.numeric(mtfs[3])
            labelMotif <- paste(reg1, reg2, sep=".vs.")
            if(!is.null(filepath))
                {
                    file <- paste(filepath, labelMotif, sep="")
                }else
                    {
                        file <- NULL
                    }
            .tni.plot.greement(rtni=rtni, estimator=estimator, duals=c(reg1, reg2), corVal=rval,file=file, alpha=alpha, lwd=lwd, lncols=lncols)
        })
}

##subfunction for 'mbr.plot.duals'
.tni.plot.greement<-function(rtni,duals,corVal,file=NULL,lncols=c("blue","red"), bgcols=lncols, lwd=0.70, alpha=0.80, estimator='spearman', sharedTargets=TRUE, mapAssignedAssociation=TRUE)
{
    ##---
    idx1 <- match(duals, names(rtni@transcriptionFactors))
    idx2 <- match(duals, rtni@transcriptionFactors)
    idxcheck<-which(is.na(idx1))
    idx1[idxcheck]<-idx2[idxcheck]
    duals<-rtni@transcriptionFactors[idx1]
    ##---
    tnet<-rtni@results$tn.ref[,duals]
    xy<-.tni.cor(rtni@gexp,tnet,asInteger=FALSE,estimator=estimator, mapAssignedAssociation=mapAssignedAssociation)
    if(sharedTargets)
        {
            idx<-rowSums(tnet!=0)==2
            tnet<-tnet[idx,]
            xy<-xy[idx,]
        } else
            {
                idx<-rowSums(xy!=0)>=1
                tnet<-tnet[idx,]
                xy<-xy[idx,]
            }
    ##---
    xlab=paste(names(duals)[1],"targets (R)")
    ylab=paste(names(duals)[2],"targets (R)")
    xlim=c(-1.0,1.0)
    ylim=c(-1.0,1.0)
    bgcols[1]<-colorRampPalette(c(lncols[1],"white"))(30)[15]
    #bgcols[2]<-"white"
    bgcols[2]<-colorRampPalette(c(lncols[2],"white"))(30)[15]
    #bgcols[4]<-"white"
    bgcols<-adjustcolor(bgcols,alpha.f=alpha)
    ##---plot
    if(!is.null(file))
        {
            pdf(file=paste(file,".pdf",sep=""), height=3, width=3)
        }
    par(mgp=c(2.2, 0.5, 0),mar=c(3.5, 3.5, 1, 1) + 0.1)
    plot.new()
    plot.window(ylim=xlim,xlim=ylim)
    axis(2,cex.axis=1,las=1,tcl=-0.15,lwd=2)
    axis(1,cex.axis=1,las=1,tcl=-0.15,lwd=2)
    title(xlab=xlab,ylab=ylab,cex.lab=1)

    if(corVal<0)
        {
            ##---negative Dual
            tpp<-xy[(sign(tnet[, 1])==1 & sign(tnet[, 2])==-1),]
            points(tpp, col=lncols[1], pch=21, cex=0.7, bg=bgcols[1], lwd=lwd)

            tpp<-xy[sign(tnet[, 1])==-1 & sign(tnet[, 2])==1,]
            points(tpp,col=lncols[1],pch=21,cex=0.7,bg="white", lwd=lwd)
        }else
            {
                ##---positive Dual
                tpp<-xy[rowSums(sign(tnet))==2, ]
                points(tpp,col=lncols[2],pch=21,cex=0.7,bg="white", lwd=lwd)

                tpp<-xy[rowSums(sign(tnet))==-2, ]
                points(tpp,col=lncols[2],pch=21,cex=0.7,bg=bgcols[2], lwd=lwd)
            }

    ##---legend
    legend("topright", legend=paste("R=", corVal, sep=" "), bty="n")
    if(!is.null(file))
        {
            dev.off()
            cat(paste("File '", paste(file,".pdf",sep=""),"' generated!\n\n", sep=""))
        }
    ##---report
    colnames(xy)<-paste(names(duals),"(R)",sep="")
    nms<-rownames(xy)
    annot<-rtni@annotation[nms,]
    report<-cbind(annot,format(round(xy,3)))
    invisible(report)
}


##subfunction for 'mbr.plot.duals'
.merge.tnis <- function (object)
{
  elreg1 <- object@TNI1@transcriptionFactors
  elreg2 <- object@TNI2@transcriptionFactors
  elregs <- c (elreg1, elreg2)
  rtni_merge <-
    new ("TNI",
         gexp = object@TNI1@gexp,
         transcriptionFactors = elregs)
  rtni_merge@annotation <- object@TNI1@annotation
  rtni_merge@para <- object@TNI1@para
  #---
  mirmt <- object@TNI2@results$tn.ref [, elreg2]
  rtni_merge@results$tn.ref <- cbind (object@TNI1@results$tn.ref [, elreg1], mirmt)
  mirmt <- object@TNI2@results$tn.dpi [, elreg2]
  rtni_merge@results$tn.dpi <- cbind (object@TNI1@results$tn.dpi [, elreg1], mirmt)
  rtni_merge@status [1:4] <- "[x]"
  return (rtni_merge)
}

##subfunction for 'mbr.plot.duals'
.namesMotifs.check <- function(motifstb, names.motifs)
    {
        if (!is.null (names.motifs))
            {
                ##----checks names.motifs
                if(sum(names.motifs%in%rownames(motifstb)) == 0) stop("-NOTE: 'names.motifs' should be in '@results$motifsInformation!' \n")
                if(sum(names.motifs%in%rownames(motifstb)) != length(names.motifs)) stop ("Not all motifs names are available! \n")
                ##----
                motifstb <- motifstb[names.motifs, c("Regulon1","Regulon2", "R")]
            } else
                {
                    motifstb <- motifstb[, c("Regulon1", "Regulon2", "R")]
                }
        motifstb[, 3] <- round(motifstb[, 3], 2)
        return(motifstb)
    }