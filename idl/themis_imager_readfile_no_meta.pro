; themis_imager_readfile.pro (c) 2006 Brian Jackel
;
;  This program may be freely distributed. Use at your own risk.
;  Bug reports are welcome, ideally with the name of an example
;  data file that causes the problem.
;+
;
; NAME:    Themis_Imager_Readfile
;
; PURPOSE: This is intended to be a general tool for reading THEMIS-GBO imager data.
;          At the moment it only deals with PGM files and has only been lightly
;          tested on full (256x256) and row2 (376x1) frames.
;
; CATEGORY: Themis, Imager, File reading
;
; CALLING SEQUENCE:  THEMIS_IMAGER_READFILE,Filename,Images,[Metadata]
;
; INPUTS: Filename  a string or array of strings containing valid image filenames
;                   or wildcard search expressions as used in "findfile".
;
; KEYWORDS: COUNT      returns the number of image frames
;           ALL_METADATA    set to obtain more metadata, much slower (default=0)
;           DEBUG      set to increase verbosity (default=0)
;
; OUTPUTS: Images     a WIDTH x HEIGHT x NFRAMES array of unsigned integers or bytes
;          Metadata     a NFRAMES element array of structures
;
; RESTRICTIONS: TBD
;
; EXAMPLES:
;
; Get one file, watch frames as movie
;
;  filename="20051225_1100_whit_themis07_full.pgm.gz"
;  THEMIS_IMAGER_READFILE,filename,images,metadata,COUNT=nframes
;  FOR indx=0,nframes-1 DO TVSCL,images[*,*,indx]
;
;
; Get 1 hour of data, summarize and display as keogram
;
;  directory="\\themis-data\data\themis\imager\stream0\2005\12\25\whit_themis07\ut11\"
;  THEMIS_IMAGER_READFILE,directory+"*full.*",images,metadata,COUNT=nframes,/DEBUG
;  keogram= TRANSPOSE(TOTAL(images[96:159,*,*],1))
;  TVSCL,keogram,ORDER=1
;
;
; NOTES:
;
;  PGM format is described on NetPBM home page at http://netpbm.sourceforge.net
;
;  gzipped files (*.pgm.gz) can be read directly in IDL, bzip2 cannot
;
;  early data (eg. ATHA 2004) were in PNG format with 1 frame per file
;
;
; MODIFICATION HISTORY:
;  2006-03-09 Bjj assembly and preliminary documentation
;  2006-06-13 Bjj add milliseconds to exposure_start_cdf and remove exposure_time_offset
;  2006-06-25 Bjj improve error handling if no comments
;-
PRO THEMIS_IMAGER_METADATA__DEFINE
  COMPILE_OPT HIDDEN
  dummy = {themis_imager_metadata    $
    ,site_uid:''          $
    ,imager_uid:''          $
    ,exposure_start_string:''       $
    ,exposure_start_cdf:0.0d0       $
    ;        ,exposure_time_offset:0.0     $
    ,exposure_duration_request:0.0     $
    ,exposure_duration_actual:0.0   $
    ,ccd_offset:[0,0]       $
    ,ccd_size:[0,0]         $
    ,ccd_binning:[0,0]        $
    ,comments:''          $
  }
END
;TO DO -add more I/O error handling
;
FUNCTION THEMIS_IMAGER_PNM_READFILE,lun,image,comments,DEBUG=debug
  COMPILE_OPT HIDDEN
  ON_ERROR,0  ;stay here
  ON_IOERROR,ioerror
  magicnumber= BYTARR(2)
  READU,lun,magicnumber
  CASE STRING(magicnumber) OF
    'P1':type=1
    'P2':type=2
    'P3':type=3
    'P4':type=4
    'P5':type=5
    'P6':type=6
    ELSE: BEGIN
      MESSAGE,'Error- unrecognized filetype, magic number is: '+STRING(magicnumber),/INFORMATIONAL
      RETURN,1
    END
  ENDCASE
  line='' & comments='' & width=0 & height=0 & maxval=-1L & nvalues=0 & values=LONARR(3)
  REPEAT BEGIN
    READF,lun,line
    poundpos= STRPOS(line,'#')
    IF (poundpos EQ -1) THEN comment='' ELSE IF (poundpos EQ 0) THEN BEGIN
      comment=line & line=''
    ENDIF ELSE BEGIN
      comment= STRMID(line,pos,999)
      line= STRMID(line,0,pos)
    ENDELSE
    IF (STRLEN(comment) GT 0) THEN comments= comments + comment + STRING(13b)
    IF (debug GE 3) THEN PRINT,'  -',comment
    line= STRCOMPRESS(STRTRIM(line,2))
    IF (STRLEN(line) GT 0) THEN BEGIN
      vals= STRSPLIT(line,' ',/EXTRACT)
      nvals= N_ELEMENTS(vals)
      values[nvalues]= vals[0:(nvals-1)<2]
      nvalues= nvalues + nvals
    ENDIF
  ENDREP UNTIL (nvalues GE 3) OR EOF(lun)
  IF EOF(lun) AND (nvalues NE 3) THEN BEGIN
    MESSAGE,'Error- end of file while reading header',/INFORMATIONAL
    RETURN,1
  ENDIF
  width= values[0]  &  height= values[1]  &  maxvalue= values[2]
  CASE type OF
    2: BEGIN
      IF (maxvalue GT 255) THEN image=UINTARR(width,height,/NOZERO) ELSE image=BYTARR(width,height,/NOZERO)
      READF,lun,image
      IF (height EQ 1) THEN image= REFORM(image,width,height)
    END
    3: BEGIN
      IF (maxvalue GT 255) THEN image=UINTARR(3,width,height) ELSE image=BYTARR(3,width,height,/NOZERO)
      READF,lun,image
      IF (height EQ 1) THEN image= REFORM(image,3,width,height)
    END
    5: BEGIN
      IF (maxvalue GT 255) THEN image=UINTARR(width,height,/NOZERO) ELSE image=BYTARR(width,height,/NOZERO)
      READU,lun,image
      BYTEORDER,image,/HTONS
      IF (height EQ 1) THEN image= REFORM(image,width,height)
    END
    6: BEGIN
      IF (maxvalue GT 255) THEN image=UINTARR(3,width,height,/NOZERO) ELSE image=BYTARR(3,width,height,/NOZERO)
      READU,lun,image
      BYTEORDER,image,/HTONS
      IF (height EQ 1) THEN image= REFORM(image,3,width,height)
    END
    ELSE:MESSAGE,'Sorry, PNM image type '+STRING(type)+' not yet implemented'
  ENDCASE
  RETURN,0
  ioerror:PRINT,BOOM,!ERROR_STATE.MSG & RETURN,1
END
; Digging through header strings with IDL6.1 regular expressions takes more than
; half the total time.  Replacing various ranges (eg. {4,16} -> + ) helped a bit,
; but it is still slow.  Default to return subset of essential information (eg. time)
; and only parse everything if /ALL_METADATA switch is set.
;
FUNCTION THEMIS_IMAGER_PARSE_COMMENTS,comments,metadata,ALL_METADATA=all_metadata
  COMPILE_OPT HIDDEN
  metadata= {THEMIS_IMAGER_METADATA}
  metadata.comments= comments[0]
  FOR indx=1,N_ELEMENTS(comments)-1 DO metadata.comments= metadata.comments + STRING(13b) + comments[indx]
  tmp= STRLOWCASE(metadata.comments)  ;avoid doing /FOLD_CASE for all STREGEX
  IF (STRLEN(tmp) EQ 0) THEN RETURN,1
  ON_IOERROR,ioerror
  timestring= (STREGEX(tmp,'"image request start" *([^#]+) utc',/SUBEXPR,/EXTRACT))[1]
  IF (timestring EQ "") THEN timestring= (STREGEX(tmp,'time *([^#]+) *$',/SUBEXPR,/EXTRACT))[1]
  IF (timestring EQ "") THEN BEGIN
    MESSAGE,'Error- could not find time information'
    RETURN,1
  ENDIF
  metadata.exposure_start_string= timestring ;(STRSPLIT(timestring,'.',/EXTRACT))[0]
  year=0 & month=0 & day=0 & hour=0 & minute=0 & second=0.0; & fraction=""
  ;READS,timestring,year,month,day,hour,minute,second,fraction,FORMAT='(I4,X,I2,X,I2,X,I2,X,I2,X,I2,X,A)'
  READS,timestring,year,month,day,hour,minute,second,FORMAT='(I4,X,I2,X,I2,X,I2,X,I2,X,F9.7)'
  milli= ROUND(1000*(second-FIX(second))) & second= FIX(second)
  ;  IF (hour EQ 0) AND (minute EQ 0) AND (second EQ 0) THEN $
  ;    milli= milli + 1000L*(second + 60L*(minute + 60L*hour)) ;see CDF_EPOCH help info...
  CDF_EPOCH,epoch,year,month,day,hour,minute,second,milli,/COMPUTE
  metadata.exposure_start_cdf=epoch
  IF KEYWORD_SET(ALL_METADATA) THEN BEGIN
    metadata.site_uid= (STREGEX(tmp,'"site unique *id" ([a-z0-9-]+)',/SUBEXPR,/EXTRACT))[1]
    metadata.imager_uid= (STREGEX(tmp,'"imager unique *id" ([a-z0-9-]+)',/SUBEXPR,/EXTRACT))[1]
    exposure= STREGEX(tmp,'"exposure options"[^#]*',/EXTRACT)
    metadata.ccd_size= (STREGEX(exposure,'width=([0-9]+).*height=([0-9]+)',/SUBEXPR,/EXTRACT))[1:2]
    metadata.ccd_offset= (STREGEX(exposure,'xoffset=([0-9]+).*yoffset=([0-9]+)',/SUBEXPR,/EXTRACT))[1:2]
    metadata.ccd_binning= (STREGEX(exposure,'xbin=([0-9]+).*ybin=([0-9]+)',/SUBEXPR,/EXTRACT))[1:2]
    metadata.exposure_duration_request= (STREGEX(exposure,'msec=([0-9]+)',/SUBEXPR,/EXTRACT))[1]
    metadata.exposure_duration_actual= (STREGEX(tmp,'"exposure.*plus.*readout" *([0-9\.]+) ms',/SUBEXPR,/EXTRACT))[1]
    ;convert milliseconds to seconds
    metadata.exposure_duration_request= metadata.exposure_duration_request/1d3
    metadata.exposure_duration_actual= metadata.exposure_duration_actual/1d3
  ENDIF
  RETURN,0
  ioerror:RETURN,1
END
PRO THEMIS_IMAGER_READFILE_NO_META,filename,images,metadata,COUNT=n_frames,DEBUG=debug,ALL_METADATA=all_metadata
  ON_ERROR,0
  IF (N_ELEMENTS(debug) EQ 0) THEN debug=0
  time0= SYSTIME(1)
  filenames=''  &  nfiles= 0
  FOR indx=0,N_ELEMENTS(filename)-1 DO BEGIN
    fname= FINDFILE(filename[indx],COUNT=nf)
    IF (nf GT 0) THEN filenames=[filenames,fname]
  ENDFOR
  nfiles= N_ELEMENTS(filenames)-1
  IF (nfiles EQ 0) THEN BEGIN
    MESSAGE,'Error- files not found:'+filename[0],/INFORMATIONAL
    n_frames=0
    RETURN
  ENDIF
  filenames= filenames[1:nfiles]
  filenames= filenames[SORT(filenames)]
  IF (debug GT 0) THEN PRINT,N_ELEMENTS(filenames),FORMAT='("found ",I," files")'
  ;pre-allocating memory significantly increases speed
  nchunk= 20 & nstart= (nchunk*nfiles)<2400
  n_frames= 0  &  n_bytes= 0
  FOR indx=0,nfiles-1 DO BEGIN
    IF (debug GT 0) THEN PRINT,' reading file: '+filenames[indx]
    ON_IOERROR,fail
    OPENR,lun,filenames[indx],/GET_LUN,COMPRESS=STREGEX(STRUPCASE(filenames[indx]),'.*\.GZ$',/BOOLEAN),/SWAP_IF_LITTLE_ENDIAN
    WHILE NOT EOF(lun) DO BEGIN
      IF (debug GE 2) THEN PRINT,' -reading frame: '+STRING(n_frames)
      ; IF THEMIS_IMAGER_PNM_READFILE(lun,image,comments,DEBUG=debug) THEN BREAK
      image= PAM_READFILE(LUN=lun,COMMENTS=comments,DEBUG=debug)
      IF (image[0] EQ -1) THEN BREAK
      ;IF THEMIS_IMAGER_PARSE_COMMENTS(comments,mdata,ALL_METADATA=all_metadata) THEN BREAK
      IF (n_frames EQ 0) THEN BEGIN
        isize= SIZE(image,/STRUCT)  ;& stop
        dimensions= isize.dimensions[0:isize.n_dimensions]
        dimensions[isize.n_dimensions]= nstart
        images= MAKE_ARRAY(dimensions,TYPE=isize.type,/NOZERO)
        metadata= REPLICATE({THEMIS_IMAGER_METADATA},nstart)
        dimensions[isize.n_dimensions]= nchunk
      ENDIF ELSE IF (n_frames GE nstart) THEN BEGIN ;need to expand the arrays
        images= [ [[images]], [[MAKE_ARRAY(dimensions,TYPE=isize.type,/NOZERO)]] ]
        metadata= [metadata, REPLICATE({THEMIS_IMAGER_METADATA},nchunk)]
        nstart= nstart+nchunk
      ENDIF
      ;copy previous metadata that may not be present in every record
      IF (n_frames GT 0) THEN BEGIN
        mdata.site_uid= metadata[n_frames-1].site_uid
        mdata.imager_uid= metadata[n_frames-1].imager_uid
      ENDIF
      ; TO DO: check for size differences
      ;metadata[n_frames]= mdata
      images[0,0,n_frames]= image
      n_frames= n_frames+1
      ;  IF (debug GE 2) THEN PRINT,'.',FORMAT='(I,$)'
    ENDWHILE
    ; IF (DEBUG GE 2) THEN PRINT,' '
    n_bytes= n_bytes + (FSTAT(lun)).cur_ptr
    fail:FREE_LUN,lun
  ENDFOR
  ;remove extra unused memory
  IF (n_frames GT 0) THEN BEGIN
    ;metadata= metadata[0:n_frames-1]
    images= images[*,*,0:n_frames-1]
  ENDIF
  IF (debug GT 0) THEN BEGIN
    dtime= (SYSTIME(1)-time0)>1  &  indx=0
    WHILE (n_bytes GT 9*1024L) DO BEGIN
      n_bytes= n_bytes / 1024.0 & indx= indx+1
    ENDWHILE
    prefix= (['','kilo','Mega','Giga','Tera'])[indx]
    infoline=STRING(n_bytes,prefix,dtime,8*n_bytes/dtime,prefix $
      ,FORMAT='(" read ",F6.1,X,A,"bytes in ",I," seconds: ",F7.1,X,A,"bits/second")')
    PRINT,STRCOMPRESS(infoline)
  ENDIF
END
;Benchmark/optimizing (note ALL_METADATA=0)
;Windows share is bandwidth limited by UCalgary 100 Mbps network:
;
; f=findfile('\data\themis\imager\stream0\2005\12\09\atha_themis02\ut08\*full.*',COUNT=nf)
; THEMIS_IMAGER_READFILE,f[*],images,metadata,COUNT=nframes,DEBUG=1
; reading file: \\themis-data\data\themis\imager\stream0\2005\12\09\atha_themis02\ut08\20051209_0800_atha_themis02_full.pgm.gz
; ...
; reading file: \\themis-data\data\themis\imager\stream0\2005\12\09\atha_themis02\ut08\20051209_0859_atha_themis02_full.pgm.gz
; read 150.5 Megabytes in 13 seconds: 88.4 Megabits/second
;Local disk is significantly faster:
;
; f=findfile('\data\themis\imager\stream0\2005\12\09\atha_themis02\ut08\*full.*',COUNT=nf)
; THEMIS_IMAGER_READFILE,f[*],images,metadata,COUNT=nframes,DEBUG=1
; reading file: \data\themis\imager\stream0\2005\12\09\atha_themis02\ut08\20051209_0800_atha_themis02_full.pgm.gz
; ...
; reading file: \data\themis\imager\stream0\2005\12\09\atha_themis02\ut08\20051209_0859_atha_themis02_full.pgm.gz
; read 150.5 Megabytes in 4 seconds: 269.4 Megabits/second
; Pegasus 4-disk RAID-5 NAS on a Gigabit link does only 120 Mbps.
;