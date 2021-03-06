#' A function to cluster flow cytometry data by one fluorescence dimension in to "on" and "off" populations.
#'
#' Cluster data in a \code{\link[flowCore]{flowFrame}} using the \code{\link[flowClust]{flowClust}}
#' package. Given a fluorescence channel and, optionally, prior values for the on and off
#' peak locations, determines how many clusters there are and produces information on the populations.
#'
#' @param fF a \code{\link[flowCore]{flowFrame}} to cluster.
#' @param channel the fluorescence channel on which to cluster.
#' @param threshold the for plasmid-bearing when only one cluster is found.
#' @param do.plot a Boolean flag to determine whether to produce plots showing the trimming of each flowFrame. Defaults to \code{FALSE}.
#'
#' @return a \code{\link{data.frame}} containing \code{num_samples}, the
#' number of samples clustered, \code{max_clust_mean}, the mean value of fluoresence
#' in the "on" cluster, and \code{max_clust_prop}, the proportion of the total
#' population that is "on".
#' @export
#'
#' @examples
iclClust <- function(fF, channel, threshold, do.plot){
  ## Remove any NaN, NA, Inf or -Inf values from the flowFrame
  fF <- flowCore::Subset(fF, as.logical(is.finite(flowCore::exprs(fF[, channel]))))

  ## calculate clusters for K=1 and K=2
  flowClust.res <- flowClust::flowClust(fF, varNames = c(channel), K = 1:2, criterion = "ICL");

  ## get the results for the K with the best ICL
  flowClust.res <- flowClust.res[[flowClust.res@index]]
  est <- flowClust::getEstimates(flowClust.res, fF)

  ## If there is only 1 cluster, is it plasmid-free or plasmid-bearing
  if (length(est$locationsC) == 1) {
    ## if the peak is above the threshold assume it is plasmid-bearing...
    if (est$locationsC > threshold) {
      newF <- data.frame(num_samples = length(flowClust.res@label),
                         max_clust_mean = est$locationsC,
                         max_clust_prop = est$proportions)

      ## otherwise assume it is plasmid-free
    } else {
      newF <- data.frame(num_samples = length(flowClust.res@label),
                         max_clust_mean = est$locationsC,
                         max_clust_prop = 0)
    }

    ## otherwise take the proportion of the peak with the highest mean fluorescence
  } else {
    newF <- data.frame(num_samples = length(flowClust.res@label),
                       max_clust_mean = est$locationsC[which.max(est$locationsC)],
                       max_clust_prop = est$proportions[which.max(est$locationsC)])
  }
  if (do.plot) {
    filename <- substr(flowCore::keyword(fF, "FILENAME"), 1, nchar(flowCore::keyword(fF, "FILENAME")) - 4)
    grDevices::pdf(file = paste(filename, "_ICL_clusters.pdf", sep = ""), width = 4, height = 4)

    flowClust::plot(x = flowClust.res, data = fF)

    grDevices::dev.off()
    # splt.fF <- flowClust::split(fF, flowClust.res)
    #
    # plt <- ggplot2::ggplot() +
    #   ggplot2::geom_density(data = as.data.frame(splt.fF[[1]][, channel]@exprs),
    #                         ggplot2::aes(x = splt.fF[[1]][, channel]@exprs, y = ..count..),
    #                         alpha = 0.5,
    #                         fill = "black")+
    #   ggplot2::geom_density(data = as.data.frame(splt.fF[[2]][, channel]@exprs),
    #                      ggplot2::aes(x = splt.fF[[2]][, channel]@exprs, y = ..count..),
    #                      alpha = 0.5,
    #                      fill = "green")+
    #   ggplot2::xlab(channel) +
    #   ggplot2::ylab("") +
    #   ggplot2::xlim(0, 7) +
    #   ggplot2::theme_bw()+
    #   ggplot2::theme(axis.text.y = ggplot2::element_blank(),
    #                  axis.ticks.y = ggplot2::element_blank(),
    #                  strip.text.x = ggplot2::element_text(size=14),
    #                  strip.background = ggplot2::element_rect(colour="white"),
    #                  axis.text = ggplot2::element_text(size=10),
    #                  axis.text.x = ggplot2::element_text(angle=-40, vjust = 0.5),
    #                  axis.title = ggplot2::element_text(size=14),
    #                  text=ggplot2::element_text(family='Garamond'),
    #                  panel.grid.major=ggplot2::element_blank(),
    #                  panel.grid.minor=ggplot2::element_blank(),
    #                  panel.border=ggplot2::element_blank(),
    #                  axis.line=ggplot2::element_line(),
    #                  legend.title=ggplot2::element_blank())
    #
    # ggplot2::ggsave(filename = paste(filename, "_clusters.png", sep=""), plot = plt)
    print(paste("Plotting cluster ", flowCore::identifier(fF)))
  }

  return(newF)
}
