#' Plotting a gene of interest in selected cells on the spatial image.
#' @param sample_names Character vector containing the name of the sample.
#' @param bcs_merge Data frame containing imagerow, imagecol and barcode of the cells belonging to the spatial image. It can also be created by the function scaling_spatial_image_parameter by selecting the output parameter 10.
#' @param images_tibble Tbl-df containing the sample name, grob, height and width of the spatial image. It can also be created by the function scaling_spatial_image_parameter by selecting the output parameter 5.
#' @param matrix Data frame containing all the genes detected per cells. This data frame can be obtained by the scaling_parameters functions.
#' @param marker Character vector containing the name of a gene of interest.
#' @param GEX_barcode Character vector containing the GEX barcode of the cell of interest with the -1 at the end
#' @param title Character vector to name the plot.
#' @param threshold Number, to define the threshold. If threshold = No, plot of the module and if threshold is a number, plot show the cells above the threshold.
#' @param size Number, to define the size of the text, default = 15.
#' @return Returns a plot of the level of expression of a gene in cells.
#' @export
#' @examples
#' \dontrun{
#' GEX_BCR_barcode<-vgm_with_simulated_VDJ$VDJ$GEX_barcode
#' GEX_BCR_barcode<-paste0(GEX_BCR_barcode,"-1") #Add -1 at the end of each barcode
#' #Without expression threshold
#' Spatial_marker_expression(matrix=scaling_parameters[[9]], marker="CD3E",bcs_merge=scaling_parameters[[10]],
#' images_tibble=scaling_parameters[[5]],GEX_barcode=GEX_BCR_barcode,sample_names=sample_names, title = "B cells",
#' threshold = "No")
#' 
#' #With expression threshold
#' Spatial_marker_expression(matrix=scaling_parameters[[9]], marker="CD3E",bcs_merge=scaling_parameters[[10]],
#' images_tibble=scaling_parameters[[5]],GEX_barcode=GEX_BCR_barcode,sample_names=sample_names, title = "B cells",
#' threshold = 5)
#' }

Spatial_marker_expression<-function(sample_names,bcs_merge,images_tibble,matrix,marker, GEX_barcode,title,threshold,size){
  
  if(missing(sample_names)) stop("Please provide sample_names input for this function")
  if(missing(images_tibble)) stop("Please provide images_tibble input for this function")
  if(missing(bcs_merge)) stop("Please provide bcs_merge input for this function")
  if(missing(matrix)) stop("Please provide matrix input for this function")
  if(missing(marker)) stop("Please provide marker input for this function")
  if(missing(GEX_barcode)) stop("Please provide GEX_barcode input for this function or checked that the barcodes contain the -1 at the end")
  if(missing(title)){
    title <- ""}
  if(missing(size)){
    size = 15
  }
  if (missing(threshold)){
    threshold = "No"
  }
  #bind bcs_merge with markers
  test<-bind_cols(bcs_merge,as.data.table(matrix)[, marker, with=FALSE])
  #subset of bcs_merge containing only cell selected
  bcs_merge_subset<-list()
  for (i in 1:length(GEX_barcode)){
    a<-filter(test, barcode == GEX_barcode[[i]])
    bcs_merge_subset<-rbind(bcs_merge_subset,a)
  }
  names(bcs_merge_subset)[13]<-"marker"
  #Without threshold
  if (threshold == "No"){
    #colors
    myPalette <- colorRampPalette(rev(brewer.pal(11, "Spectral")))
    #plot
    p<-ggplot(bcs_merge_subset,aes(x=imagecol,y=imagerow,fill=marker)) +
      geom_spatial(data=images_tibble[1,], aes(grob=grob), x=0.5, y=0.5)+
      geom_point(shape = 21, colour = "black", size = 1.75, stroke = 0.5)+
      coord_cartesian(expand=FALSE)+
      scale_fill_gradientn(colours = myPalette(100))+
      xlim(0,max(bcs_merge %>% 
                   filter(sample ==sample_names[1]) %>% 
                   select(width)))+
      ylim(max(bcs_merge %>% 
                 filter(sample ==sample_names[1]) %>% 
                 select(height)),0)+
      xlab("") +
      ylab("") +
      ggtitle(sample_names[1],title)+
      theme(axis.text=element_text(size=size),
            axis.title=element_text(size=size))+
      labs(fill = marker)+
      theme_set(theme_bw(base_size = size))+
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(),
            panel.background = element_blank(), 
            axis.line = element_line(colour = "black"),
            axis.text = element_blank(),
            axis.ticks = element_blank())
  } else{
    #thresholding
    for (i in 1:length(bcs_merge_subset$barcode)){
      if (bcs_merge_subset$marker[[i]]>=threshold){
        bcs_merge_subset$threshold[[i]] = 1
      } else{
        bcs_merge_subset$threshold[[i]] = 0
      }
    }
    #Add the threshold column to dataframe
    bcs_merge_subset$threshold<-as.numeric(bcs_merge_subset$threshold)
    bcs_merge_subset<-filter(bcs_merge_subset,threshold==1)
    #plot
    p<-ggplot(data = bcs_merge_subset, aes(x=imagecol,y=imagerow, fill = as.factor(threshold)))+
      geom_spatial(data=images_tibble[1,], aes(grob=grob), x=0.5, y=0.5)+
      geom_point(shape=21, colour = "black", size = 1.75, stroke = 0.5)+
      coord_cartesian(expand=FALSE)+
      scale_fill_discrete(guide = guide_legend(reverse=TRUE))+
      xlim(0,max(bcs_merge %>% 
                   filter(sample ==sample_names[1]) %>% 
                   select(width)))+
      ylim(max(bcs_merge %>% 
                 filter(sample ==sample_names[1]) %>% 
                 select(height)),0)+
      xlab("") +
      ylab("") +
      ggtitle(sample_names[1], title)+
      theme(axis.text=element_text(size=size),
            axis.title=element_text(size=size))+
      labs(fill = marker)+
      guides(fill = guide_legend(override.aes = list(size=3)))+
      theme_set(theme_bw(base_size = size))+
      theme(legend.key = element_rect(fill = "white"))+
      theme(panel.grid.major = element_blank(), 
            panel.grid.minor = element_blank(),
            panel.background = element_blank(), 
            axis.line = element_line(colour = "black"),
            axis.text = element_blank(),
            axis.ticks = element_blank())
  }
  return(p)
}
