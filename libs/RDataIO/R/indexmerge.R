`indexmerge` <-
function(lrndata,bm=NULL,cls=NULL){
  # indexmerge Match matrix rows by row names.
  # INPUT
  # lrndata is the data matrix. bm and cls are optional row-indexed inputs.
  # OUTPUT
  # A list with lrndata, bm, and cls, matched by row names.
  # The lrndata element is a matrix.
  # SPDX-License-Identifier: AGPL-3.0-only
  # Additional permission: see MATLAB-EXCEPTION.txt.

if (is.null(bm))
   { if (!is.null(cls))
        { m1 = merge(lrndata,cls,by=0,sort=FALSE)
          lrndata=m1[,(1:ncol(lrndata))+1]
          cls[,1] = m1[,(1:ncol(cls))+ncol(lrndata)+1]
          rownames(lrndata)=rownames(cls)=m1[,1]
        }
   }
else if (is.null(cls) && !is.null(bm))
        { m1 = merge(lrndata,bm,by=0,sort=FALSE)
          lrndata=m1[,(1:ncol(lrndata))+1]
          bm = m1[,(1:ncol(bm))+ncol(lrndata)+1]
          rownames(lrndata)=rownames(bm)=m1[,1]
        }



else { m2 = merge(lrndata,cls,by=0,sort=FALSE)
       rownames(m2) = m2[,1]
       M  = merge(m2[,(1:(ncol(lrndata)+ncol(cls)))+1],bm,by=0,sort=FALSE)
       lrndata = M[,(1:ncol(lrndata))+1]
       cls[,1] = M[,(1:ncol(cls))+ncol(lrndata)+1]
       bm =  M[,(1:ncol(bm))+ncol(lrndata)+ncol(cls)+1]
       rownames(lrndata)=rownames(cls)=rownames(bm)=M[,1]
     }
return(list(lrndata=as.matrix(lrndata),bm=bm,cls=cls))
}

