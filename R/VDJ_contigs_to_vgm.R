#' Formats "VDJ_contigs_annotations.csv" files from cell ranger to match the VDJ_GEX_matrix output using only cells with 1VDJ and 1VJ chain
#' @param directory list containing paths to the "filtered_contig_annotations.csv" files from cell ranger.
#' @param sample.names vector specifying sample names.
#' @param celltype Character. Either "Tcells" or "Bcells".
#' @param FB Integer specifying whether VGM should contain Feature Barcode columns or not. Default set to FALSE. 
#' @param platypus.version Function based on VGM object from V3, no need to set this parameter.
#' @return data frame with column names that match the VDJ_GEX_matrix output. Can be appended to the VDJ_GEX_matrix output
#' @export
#' @examples
#' \dontrun{
#' directory.list <- list()
#' directory.list[[1]] <- c("~/Dataset_1/filtered_contig_annotations.csv")
#' directory.list[[2]] <- c("~/Dataset_1/filtered_contig_annotations.csv")
#' filtered_contig_vgm <- VDJ_contigs_to_vgm(directory = directory.list, sample.names = c(s3,s4), celltype = "Tcells")
#' }

VDJ_contigs_to_vgm <- function(directory,
                               sample.names,
                               celltype,
                               FB,
                               platypus.version){
  ###
  if(missing(directory)){
    stop("Please provide list of local paths to 'filtered_contig_annotations.csv' files")
  }
  if(missing(sample.names)){
    stop("Please provide sample names")
  }
  if(missing(celltype)){
    stop("Please specify celltype")
  }
  if(missing(FB)){
    FB <- F
  }
  platypus.version <- "v3"
  
  chain_vdj <- NULL
  chain_vj <- NULL
  
  print(Sys.time())
  all_formatted_df <- list()
  for (k in 1:length(directory)) {
    filtered_contig_annotations <- utils::read.csv(file = directory[[k]]) #read in csv
    filtered_contig_annotations$full_length <- gsub(pattern = "True", replacement = "true", filtered_contig_annotations$full_length)
    filtered_contig_annotations$productive <- gsub(pattern = "True", replacement = "true", filtered_contig_annotations$productive)
    
    #filter data
    filtered_contig_annotations <- subset(filtered_contig_annotations, filtered_contig_annotations$full_length == "true" & filtered_contig_annotations$productive == "true")
    filtered_contig_annotations <- subset(filtered_contig_annotations, !filtered_contig_annotations$barcode%in%filtered_contig_annotations$barcode[filtered_contig_annotations$chain == "Multi"])
    unique_barcodes <- unique(filtered_contig_annotations$barcode)
    
    unpaired <- list()
    for (j in 1:length(unique_barcodes)) { #removing cells that do not fit criteria 1HC1LC
      if(length(which(filtered_contig_annotations$barcode == unique_barcodes[j])) == 1 | length(which(filtered_contig_annotations$barcode == unique_barcodes[j])) > 2) {
        unpaired[[length(unpaired)+1]] <- filtered_contig_annotations$barcode[which(filtered_contig_annotations$barcode == unique_barcodes[j])]
      } else {next}}
    unpaired <- unlist(unpaired)
    paired_df <- subset(filtered_contig_annotations, !filtered_contig_annotations$barcode%in%unpaired)
    
    if(celltype == "Bcells"){
      unique_barcodes <- unique(paired_df$barcode)
      index_remove <- list()
      for (j in 1:length(unique_barcodes)) { #removing cells that are double IGH/IGK/IGL
        if(length(which(paired_df$chain[paired_df$barcode == unique_barcodes[j]] == "IGH")) >1) {
          index_remove[[length(index_remove)+1]] <- unique(paired_df$barcode[which(paired_df$barcode == unique_barcodes[j] & paired_df$chain == "IGH")])
        }
        if(length(which(paired_df$chain[paired_df$barcode == unique_barcodes[j]] == "IGK")) >1){
          index_remove[[length(index_remove)+1]] <- unique(paired_df$barcode[which(paired_df$barcode == unique_barcodes[j] & paired_df$chain == "IGK")])
        } 
        if(length(which(paired_df$chain[paired_df$barcode == unique_barcodes[j]] == "IGL")) >1){
          index_remove[[length(index_remove)+1]] <- unique(paired_df$barcode[which(paired_df$barcode == unique_barcodes[j] & paired_df$chain == "IGL")])
        } else {next}}
      index_remove <- unlist(index_remove)
      paired_df <- subset(paired_df, !paired_df$barcode%in%index_remove)
      #now only cells with 1HC1LC are left
      
      paired_df$chain_vdj <- NA
      paired_df$chain_vj <- NA
      paired_df$chain_vdj[which(paired_df$chain == "IGH")] <- "IGH"
      paired_df$chain_vj[which(paired_df$chain != "IGH")] <- paired_df$chain[which(paired_df$chain != "IGH")]
      
      
      if(FB == F){
        unique_barcodes <- unique(paired_df$barcode)
        colnames <- c("barcode", "orig_barcode", "sample_id", "FB_assignment","group_id", "clonotype_id_10x", "celltype", "Nr_of_VDJ_chains","Nr_of_VJ_chains","VDJ_cdr3s_aa", "VJ_cdr3s_aa","VDJ_cdr3s_nt","VJ_cdr3s_nt","VDJ_chain_contig","VJ_chain_contig","VDJ_chain","VJ_chain", "VDJ_vgene", "VJ_vgene","VDJ_dgene","VDJ_jgene", "VJ_jgene","VDJ_cgene","VJ_cgene","VDJ_sequence_nt_raw","VJ_sequence_nt_raw","VDJ_sequence_nt_trimmed", "VJ_sequence_nt_trimmed","VDJ_sequence_aa","VJ_sequence_aa","VDJ_trimmed_ref","VJ_trimmed_ref","VDJ_raw_consensus_id","VJ_raw_consensus_id","clonotype_frequency","specifity","affinity","GEX_available","orig.ident","orig_barcode_GEX","seurat_clusters","PC_1","PC_2","UMAP_1", "UMAP_2","tSNE_1","tSNE_2","batch_id","clonotype_id")
        formatted_df <- data.frame(matrix(ncol = length(colnames), nrow = length(unique_barcodes)))
        colnames(formatted_df) <- colnames
      }
      if(FB == T){
        unique_barcodes <- unique(paired_df$barcode)
        colnames <- c("barcode", "orig_barcode", "sample_id", "FB_assignment","group_id", "clonotype_id_10x", "celltype", "Nr_of_VDJ_chains","Nr_of_VJ_chains","VDJ_cdr3s_aa", "VJ_cdr3s_aa","VDJ_cdr3s_nt","VJ_cdr3s_nt","VDJ_chain_contig","VJ_chain_contig","VDJ_chain","VJ_chain", "VDJ_vgene", "VJ_vgene","VDJ_dgene","VDJ_jgene", "VJ_jgene","VDJ_cgene","VJ_cgene","VDJ_sequence_nt_raw","VJ_sequence_nt_raw","VDJ_sequence_nt_trimmed", "VJ_sequence_nt_trimmed","VDJ_sequence_aa","VJ_sequence_aa","VDJ_trimmed_ref","VJ_trimmed_ref","VDJ_raw_consensus_id","VJ_raw_consensus_id","clonotype_frequency","specifity","affinity","GEX_available","orig.ident","orig_barcode_GEX","seurat_clusters","PC_1","PC_2","UMAP_1", "UMAP_2","tSNE_1","tSNE_2","batch_id","clonotype_id")
        formatted_df <- data.frame(matrix(ncol = length(colnames), nrow = length(unique_barcodes)))
        colnames(formatted_df) <- colnames
        
      }
      formatted_df$sample_id <- sample.names[k]
      formatted_df$barcode <- paste0(sample.names[k], "_", unique_barcodes)
      formatted_df$Nr_of_VDJ_chains = formatted_df$Nr_of_VJ_chains = 1
      
      #fill in data frame
      for (i in 1:length(unique_barcodes)) {
        formatted_df$VDJ_chain[i] <- paired_df$chain[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "IGH")]
        formatted_df$VJ_chain[i] <- paired_df$chain[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain != "IGH")]
        formatted_df$VDJ_cdr3s_aa[i] <- paired_df$cdr3[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "IGH")]
        formatted_df$VJ_cdr3s_aa[i] <- paired_df$cdr3[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain !="IGH")]
        formatted_df$VDJ_cdr3s_nt[i] <- paired_df$cdr3_nt[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "IGH")]
        formatted_df$VJ_cdr3s_nt[i] <- paired_df$cdr3_nt[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain != "IGH")]
        formatted_df$VDJ_chain_contig[i] <- paired_df$contig_id[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "IGH")]
        formatted_df$VJ_chain_contig[i] <- paired_df$contig_id[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain != "IGH")]
        formatted_df$VDJ_vgene[i] <- gsub("\\*.*", "", stringr::str_replace(paired_df$v_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "IGH")], "/", "\\-"))
        formatted_df$VJ_vgene[i] <- gsub("\\*.*","",stringr::str_replace(paired_df$v_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain != "IGH")],"/", "\\-"))
        formatted_df$VDJ_dgene[i] <- gsub("\\*.*","",stringr::str_replace(paired_df$d_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "IGH")], "/", "\\-"))
        formatted_df$VDJ_jgene[i] <- gsub("\\*.*","", stringr::str_replace(paired_df$j_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "IGH")], "/", "\\-"))
        formatted_df$VJ_jgene[i] <- gsub("\\*.*", "", stringr::str_replace(paired_df$j_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain != "IGH")], "/", "\\-"))
        formatted_df$VDJ_cgene[i] <- gsub("\\*.*", "", stringr::str_replace(paired_df$c_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "IGH")], "/", "\\-"))
        formatted_df$VJ_cgene[i] <- gsub("\\*.*","", stringr::str_replace(paired_df$c_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain != "IGH")], "/", "\\-"))
      }
    }
    
    if(celltype == "Tcells"){
      unique_barcodes <- unique(paired_df$barcode)
      index_remove <- list()
      for (j in 1:length(unique_barcodes)) { #removing cells that are double alpha/beta
        if(length(which(paired_df$chain[paired_df$barcode == unique_barcodes[j]] == "TRA")) >1) {
          index_remove[[length(index_remove)+1]] <- unique(paired_df$barcode[which(paired_df$barcode == unique_barcodes[j] & paired_df$chain == "TRA")])
        }
        if(length(which(paired_df$chain[paired_df$barcode == unique_barcodes[j]] == "TRB")) >1){
          index_remove[[length(index_remove)+1]] <- unique(paired_df$barcode[which(paired_df$barcode == unique_barcodes[j] & paired_df$chain == "TRB")])
        } else {next}}
      index_remove <- unlist(index_remove)
      paired_df <- subset(paired_df, !paired_df$barcode%in%index_remove)
      #now only cells with 1TRA and one 1TRB are left
      
      if(FB == F){
        #start making data frame that resembles vgm
        unique_barcodes <- unique(paired_df$barcode)
        colnames <- c("barcode", "orig_barcode", "sample_id", "FB_assignment","group_id", "clonotype_id_10x", "celltype", "Nr_of_VDJ_chains","Nr_of_VJ_chains","VDJ_cdr3s_aa", "VJ_cdr3s_aa","VDJ_cdr3s_nt","VJ_cdr3s_nt","VDJ_chain_contig","VJ_chain_contig","VDJ_chain","VJ_chain", "VDJ_vgene", "VJ_vgene","VDJ_dgene","VDJ_jgene", "VJ_jgene","VDJ_cgene","VJ_cgene","VDJ_sequence_nt_raw","VJ_sequence_nt_raw","VDJ_sequence_nt_trimmed", "VJ_sequence_nt_trimmed","VDJ_sequence_aa","VJ_sequence_aa","VDJ_trimmed_ref","VJ_trimmed_ref","VDJ_raw_consensus_id","VJ_raw_consensus_id","clonotype_frequency","specifity","affinity","GEX_available","orig.ident","orig_barcode_GEX","seurat_clusters","PC_1","PC_2","UMAP_1", "UMAP_2","tSNE_1","tSNE_2","batch_id","clonotype_id")
        formatted_df <- data.frame(matrix(ncol = length(colnames), nrow = length(unique_barcodes)))
        colnames(formatted_df) <- colnames
      }
      if(FB == T){
        #start making data frame that resembles vgm
        unique_barcodes <- unique(paired_df$barcode)
        colnames <- c("barcode", "orig_barcode", "sample_id", "FB_assignment","group_id", "clonotype_id_10x", "celltype", "Nr_of_VDJ_chains","Nr_of_VJ_chains","VDJ_cdr3s_aa", "VJ_cdr3s_aa","VDJ_cdr3s_nt","VJ_cdr3s_nt","VDJ_chain_contig","VJ_chain_contig","VDJ_chain","VJ_chain", "VDJ_vgene", "VJ_vgene","VDJ_dgene","VDJ_jgene", "VJ_jgene","VDJ_cgene","VJ_cgene","VDJ_sequence_nt_raw","VJ_sequence_nt_raw","VDJ_sequence_nt_trimmed", "VJ_sequence_nt_trimmed","VDJ_sequence_aa","VJ_sequence_aa","VDJ_trimmed_ref","VJ_trimmed_ref","VDJ_raw_consensus_id","VJ_raw_consensus_id","clonotype_frequency","specifity","affinity","GEX_available","orig.ident","orig_barcode_GEX","seurat_clusters","PC_1","PC_2","UMAP_1", "UMAP_2","tSNE_1","tSNE_2","batch_id","clonotype_id")
        formatted_df <- data.frame(matrix(ncol = length(colnames), nrow = length(unique_barcodes)))
        colnames(formatted_df) <- colnames
        
      }
      formatted_df$sample_id <- sample.names[k]
      formatted_df$barcode <- paste0(sample.names[k], "_", unique_barcodes)
      formatted_df$Nr_of_VDJ_chains = formatted_df$Nr_of_VJ_chains = 1
      formatted_df$VDJ_chain <- "TRB"
      formatted_df$VJ_chain <- "TRA"
      
      #fill in data frame
      for (i in 1:length(unique_barcodes)) {
        formatted_df$VDJ_cdr3s_aa[i] <- paired_df$cdr3[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRB")]
        formatted_df$VJ_cdr3s_aa[i] <- paired_df$cdr3[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain=="TRA")]
        formatted_df$VDJ_cdr3s_nt[i] <- paired_df$cdr3_nt[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRB")]
        formatted_df$VJ_cdr3s_nt[i] <- paired_df$cdr3_nt[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRA")]
        formatted_df$VDJ_chain_contig[i] <- paired_df$contig_id[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRB")]
        formatted_df$VJ_chain_contig[i] <- paired_df$contig_id[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRA")]
        formatted_df$VDJ_vgene[i] <- gsub("\\*.*", "", stringr::str_replace(paired_df$v_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRB")], "/", "\\-"))
        formatted_df$VJ_vgene[i] <- gsub("\\*.*","",stringr::str_replace(paired_df$v_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRA")],"/", "\\-"))
        formatted_df$VDJ_dgene[i] <- gsub("\\*.*","",stringr::str_replace(paired_df$d_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRB")], "/", "\\-"))
        formatted_df$VDJ_jgene[i] <- gsub("\\*.*","", stringr::str_replace(paired_df$j_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRB")], "/", "\\-"))
        formatted_df$VJ_jgene[i] <- gsub("\\*.*", "", stringr::str_replace(paired_df$j_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRA")], "/", "\\-"))
        formatted_df$VDJ_cgene[i] <- gsub("\\*.*", "", stringr::str_replace(paired_df$c_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRB")], "/", "\\-"))
        formatted_df$VJ_cgene[i] <- gsub("\\*.*","", stringr::str_replace(paired_df$c_gene[which(paired_df$barcode == unique_barcodes[i] & paired_df$chain == "TRA")], "/", "\\-"))
      }
    }
    
    all_formatted_df[[k]] <- formatted_df #save
  }
  output_df <- do.call("rbind", all_formatted_df) #combine all data frames
  print("Done")
  print(Sys.time())
  return(output_df)
}
