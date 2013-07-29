MXMLTMPL	  ; VEN/GPL - XML templating utilities;2013-07-26  6:22 PM
	;;2.0T1;XML PROCESSING UTILITIES;;Jul 29, 2013;Build 50
	;
QUERY(IARY,XPATH,OARY)	 ; RETURNS THE XML ARRAY MATCHING THE XPATH EXPRESSION
	; XPATH IS OF THE FORM "//FIRST/SECOND/THIRD"
	; IARY AND OARY ARE PASSED BY NAME
	I '$D(@IARY@("INDEXED"))  D  ; INDEX IS NOT PRESENT IN IARY
	. D INDEX^MXMLTMP1(IARY) ; GENERATE AN INDEX FOR THE XML
	N FIRST,LAST ; FIRST AND LAST LINES OF ARRAY TO RETURN
	N TMP,I,J,QXPATH
	S FIRST=1
	I '$D(@IARY@(0)) D  ; LINE COUNT NOT IN ZERO NODE
	. S @IARY@(0)=$O(@IARY@("//"),-1) ; THIS SHOULD USUALLY WORK
	S LAST=@IARY@(0) ; FIRST AND LAST DEFAULT TO ROOT
	I XPATH'="//" D  ; NOT A ROOT QUERY
	. S TMP=@IARY@(XPATH) ; LOOK UP LINE VALUES
	. S FIRST=$P(TMP,"^",1)
	. S LAST=$P(TMP,"^",2)
	K @OARY
	S @OARY@(0)=+LAST-FIRST+1
	S J=1
	FOR I=FIRST:1:LAST  D
	. S @OARY@(J)=@IARY@(I) ; COPY THE LINE TO OARY
	. S J=J+1
	; ZWR OARY
	Q
	;
START(ISTR)	    ; EXTRINSIC TO RETURN THE STARTING LINE FROM AN INDEX
	; TYPE STRING WITH THREE PIECES ARRAY;START;FINISH
	; COMPANION TO FINISH ; IDX IS PASSED BY NAME
	Q $P(ISTR,";",2)
	;
FINISH(ISTR)	   ; EXTRINSIC TO RETURN THE LAST LINE FROM AN INDEX
	; TYPE STRING WITH THREE PIECES ARRAY;START;FINISH
	Q $P(ISTR,";",3)
	;
ARRAY(ISTR)	    ; EXTRINSIC TO RETURN THE ARRAY REFERENCE FROM AN INDEX
	; TYPE STRING WITH THREE PIECES ARRAY;START;FINISH
	Q $P(ISTR,";",1)
	;
BUILD(BLIST,BDEST)	     ; A COPY MACHINE THAT TAKE INSTRUCTIONS IN ARRAY BLIST
	; ZEXCEPT: MXMLDEBUG
	; WHICH HAVE ARRAY;START;FINISH AND COPIES THEM TO DEST
	; DEST IS CLEARED TO START
	; USES PUSH TO DO THE COPY
	N I
	K @BDEST
	F I=1:1:@BLIST@(0) D  ; FOR EACH INSTRUCTION IN BLIST
	. N J,ATMP
	. S ATMP=$$ARRAY(@BLIST@(I))
	. I $G(MXMLDEBUG) D EN^DDIOL("ATMP="_ATMP)
	. I $G(MXMLDEBUG) D EN^DDIOL(@BLIST@(I))
	. F J=$$START(@BLIST@(I)):1:$$FINISH(@BLIST@(I)) D  ;
	. . ; FOR EACH LINE IN THIS INSTR
	. . I $G(MXMLDEBUG) D EN^DDIOL("BDEST= "_BDEST)
	. . I $G(MXMLDEBUG) D EN^DDIOL("ATMP= "_@ATMP@(J))
	. . D PUSH^MXMLTMP1(BDEST,@ATMP@(J))
	Q
	;
QUEUE(BLST,ARRAY,FIRST,LAST)	   ; ADD AN ENTRY TO A BLIST
	; ZEXCEPT: MXMLDEBUG
	;
	I $G(MXMLDEBUG) D EN^DDIOL("QUEUEING "_BLST)
	D PUSH^MXMLTMP1(BLST,ARRAY_";"_FIRST_";"_LAST)
	Q
	;
CP(CPSRC,CPDEST)	       ; COPIES CPSRC TO CPDEST BOTH PASSED BY NAME
	; ZEXCEPT: MXMLDEBUG
	; KILLS CPDEST FIRST
	N CPINSTR
	I $G(MXMLDEBUG) D EN^DDIOL("MADE IT TO COPY "_CPSRC_" TO "_CPDEST)
	I @CPSRC@(0)<1 D  QUIT  ; BAD LENGTH
	. D EN^DDIOL("ERROR IN COPY BAD SOURCE LENGTH: "_CPSRC)
	; I '$D(@CPDEST@(0)) S @CPDEST@(0)=0 ; IF THE DEST IS EMPTY, INIT
	D QUEUE("CPINSTR",CPSRC,1,@CPSRC@(0)) ; BLIST FOR ENTIRE ARRAY
	D BUILD("CPINSTR",CPDEST)
	Q
	;
QOPEN(QOBLIST,QOXML,QOXPATH)	   ; ADD ALL BUT THE LAST LINE OF QOXML TO QOBLIST
	; ZEXCEPT: MXMLDEBUG
	; WARNING NEED TO DO QCLOSE FOR SAME XML BEFORE CALLING BUILD
	; QOXPATH IS OPTIONAL - WILL OPEN INSIDE THE XPATH POINT
	; USED TO INSERT CHILDREN NODES
	I @QOXML@(0)<1 D  QUIT  ; MALFORMED XML
	. D EN^DDIOL("MALFORMED XML PASSED TO QOPEN: "_QOXML)
	I $G(MXMLDEBUG) D EN^DDIOL("DOING QOPEN")
	N S1,E1,QOT,QOTMP
	S S1=1 ; OPEN FROM THE BEGINNING OF THE XML
	I $D(QOXPATH) D  ; XPATH PROVIDED
	. D QUERY(QOXML,QOXPATH,"QOT") ; INSURE INDEX
	. S E1=$P(@QOXML@(QOXPATH),"^",2)-1
	I '$D(QOXPATH) D  ; NO XPATH PROVIDED, OPEN AT ROOT
	. S E1=@QOXML@(0)-1
	D QUEUE(QOBLIST,QOXML,S1,E1)
	; S QOTMP=QOXML_"^"_S1_"^"_E1
	; D PUSH(QOBLIST,QOTMP)
	Q
	;
QCLOSE(QCBLIST,QCXML,QCXPATH)	  ; CLOSE XML AFTER A QOPEN
	; ZEXCEPT: MXMLDEBUG
	; ADDS THE LIST LINE OF QCXML TO QCBLIST
	; USED TO FINISH INSERTING CHILDERN NODES
	; QCXPATH IS OPTIONAL - IF PROVIDED, WILL CLOSE UNTIL THE END
	; IF QOPEN WAS CALLED WITH XPATH, QCLOSE SHOULD BE TOO
	I @QCXML@(0)<1 D  QUIT  ; MALFORMED XML
	. D EN^DDIOL("MALFORMED XML PASSED TO QCLOSE: "_QCXML)
	I $G(MXMLDEBUG) D EN^DDIOL("GOING TO CLOSE")
	N S1,E1,QCT,QCTMP
	S E1=@QCXML@(0) ; CLOSE UNTIL THE END OF THE XML
	I $D(QCXPATH) D  ; XPATH PROVIDED
	. D QUERY(QCXML,QCXPATH,"QCT") ; INSURE INDEX
	. S S1=$P(@QCXML@(QCXPATH),"^",2) ; REMAINING XML
	I '$D(QCXPATH) D  ; NO XPATH PROVIDED, CLOSE AT ROOT
	. S S1=@QCXML@(0)
	D QUEUE(QCBLIST,QCXML,S1,E1)
	; D PUSH(QCBLIST,QCXML_";"_S1_";"_E1)
	Q
	;
INSERT(INSXML,INSNEW,INSXPATH)	 ; INSERT INSNEW INTO INSXML AT THE
	; ZEXCEPT: MXMLDEBUG
	; INSXPATH XPATH POINT INSXPATH IS OPTIONAL - IF IT IS
	; OMITTED, INSERTION WILL BE AT THE ROOT
	; NOTE INSERT IS NON DESTRUCTIVE AND WILL ADD THE NEW
	; XML AT THE END OF THE XPATH POINT
	; INSXML AND INSNEW ARE PASSED BY NAME INSXPATH IS A VALUE
	N INSBLD,INSTMP
	I $G(MXMLDEBUG) D EN^DDIOL("DOING INSERT "_INSXML_" "_INSNEW_" "_INSXPATH)
	I $G(MXMLDEBUG),$O(@INSXML@("")) N G1 F G1=1:1:@INSXML@(0) D EN^DDIOL(@INSXML@(G1))
	I '$D(@INSXML@(1)) D  QUIT  ; INSERT INTO AN EMPTY ARRAY
	. D CP^MXMLTMPL(INSNEW,INSXML) ; JUST COPY INTO THE OUTPUT
	I $D(@INSXML@(1)) D  ; IF ORIGINAL ARRAY IS NOT EMPTY
	. I '$D(@INSXML@(0)) S @INSXML@(0)=$O(@INSXML@(""),-1) ;SET LENGTH
	. I $D(INSXPATH) D  ; XPATH PROVIDED
	. . D QOPEN("INSBLD",INSXML,INSXPATH) ; COPY THE BEFORE
	. . I $G(MXMLDEBUG) D PARY^MXMLTMPL("INSBLD")
	. I '$D(INSXPATH) D  ; NO XPATH PROVIDED, OPEN AT ROOT
	. . D QOPEN("INSBLD",INSXML,"//") ; OPEN WITH ROOT XPATH
	. I '$D(@INSNEW@(0)) S @INSNEW@(0)=$O(@INSNEW@(""),-1) ;SIZE OF XML
	. D QUEUE("INSBLD",INSNEW,1,@INSNEW@(0)) ; COPY IN NEW XML
	. I $D(INSXPATH) D  ; XPATH PROVIDED
	. . D QCLOSE("INSBLD",INSXML,INSXPATH) ; CLOSE WITH XPATH
	. I '$D(INSXPATH) D  ; NO XPATH PROVIDED, CLOSE AT ROOT
	. . D QCLOSE("INSBLD",INSXML,"//") ; CLOSE WITH ROOT XPATH
	. D BUILD("INSBLD","INSTMP") ; PUT RESULTS IN INDEST
	. D CP^MXMLTMPL("INSTMP",INSXML) ; COPY BUFFER TO SOURCE
	Q
	;
INSINNER(INNXML,INNNEW,INNXPATH)	       ; INSERT THE INNER XML OF INNNEW
	; INTO INNXML AT THE INNXPATH XPATH POINT
	;
	N INNBLD,UXPATH
	N INNTBUF
	S INNTBUF=$NA(^TMP($J,"INNTBUF"))
	K @INNTBUF
	I '$D(INNXPATH) D  ; XPATH NOT PASSED
	. S UXPATH="//" ; USE ROOT XPATH
	I $D(INNXPATH) S UXPATH=INNXPATH ; USE THE XPATH THAT'S PASSED
	I '$D(@INNXML@(0)) D  ; INNXML IS EMPTY
	. D QUEUE^MXMLTMPL("INNBLD",INNNEW,2,@INNNEW@(0)-1) ; JUST INNER
	. D BUILD("INNBLD",INNXML)
	I @INNXML@(0)>0  D  ; NOT EMPTY
	. D QOPEN("INNBLD",INNXML,UXPATH) ;
	. D QUEUE("INNBLD",INNNEW,2,@INNNEW@(0)-1) ; JUST INNER XML
	. D QCLOSE("INNBLD",INNXML,UXPATH)
	. D BUILD("INNBLD",INNTBUF) ; BUILD TO BUFFER
	. D CP(INNTBUF,INNXML) ; COPY BUFFER TO DEST
	K @INNTBUF
	Q
	;
INSB4(XDEST,XNEW)	; INSERT XNEW AT THE BEGINNING OF XDEST
	; ZEXCEPT: MXMLDEBUG
	; BUT XDEST AN XNEW ARE PASSED BY NAME
	N XBLD,XTMP
	D QUEUE("XBLD",XDEST,1,1) ; NEED TO PRESERVE SECTION ROOT
	D QUEUE("XBLD",XNEW,1,@XNEW@(0)) ; ALL OF NEW XML FIRST
	D QUEUE("XBLD",XDEST,2,@XDEST@(0)) ; FOLLOWED BY THE REST OF SECTION
	D BUILD("XBLD","XTMP") ; BUILD THE RESULT
	D CP("XTMP",XDEST) ; COPY TO THE DESTINATION
	I $G(MXMLDEBUG) D PARY("XDEST")
	Q
	;
REPLACE(REXML,RENEW,REXPATH)	   ; REPLACE THE XML AT THE XPATH POINT
	; ZEXCEPT: MXMLDEBUG
	; WITH RENEW - NOTE THIS WILL DELETE WHAT WAS THERE BEFORE
	; REXML AND RENEW ARE PASSED BY NAME XPATH IS A VALUE
	; THE DELETED XML IS PUT IN ^TMP($J,"REPLACE_OLD")
	N REBLD,XFIRST,XLAST,OLD,XNODE,RTMP
	S OLD=$NA(^TMP($J,"REPLACE_OLD"))
	K @OLD
	D QUERY(REXML,REXPATH,OLD) ; CREATE INDEX, TEST XPATH, MAKE OLD
	S XNODE=@REXML@(REXPATH) ; PULL OUT FIRST AND LAST LINE PTRS
	S XFIRST=$P(XNODE,"^",1)
	S XLAST=$P(XNODE,"^",2)
	I RENEW="" D  ; WE ARE DELETING A SECTION, MUST SAVE THE TAG
	. D QUEUE("REBLD",REXML,1,XFIRST) ; THE BEFORE
	. D QUEUE("REBLD",REXML,XLAST,@REXML@(0)) ; THE REST
	I RENEW'="" D  ; NEW XML IS NOT NULL
	. D QUEUE("REBLD",REXML,1,XFIRST-1) ; THE BEFORE
	. D QUEUE("REBLD",RENEW,1,@RENEW@(0)) ; THE NEW
	. D QUEUE("REBLD",REXML,XLAST+1,@REXML@(0)) ; THE REST
	I $G(MXMLDEBUG) D EN^DDIOL("REPLACE PREBUILD")
	I $G(MXMLDEBUG) D PARY("REBLD")
	D BUILD("REBLD","RTMP")
	K @REXML ; KILL WHAT WAS THERE
	D CP("RTMP",REXML) ; COPY IN THE RESULT
	K @OLD
	Q
	;
DELETE(REXML,REXPATH)	   ; DELETE THE XML AT THE XPATH POINT
	; ZEXCEPT: MXMLDEBUG
	; REXML IS PASSED BY NAME XPATH IS A VALUE
	N REBLD,XFIRST,XLAST,OLD,XNODE,RTMP
	S OLD=$NA(^TMP($J,"REPLACE_OLD"))
	K @OLD
	D QUERY(REXML,REXPATH,OLD) ; CREATE INDEX, TEST XPATH, MAKE OLD
	S XNODE=@REXML@(REXPATH) ; PULL OUT FIRST AND LAST LINE PTRS
	S XFIRST=$P(XNODE,"^",1)
	S XLAST=$P(XNODE,"^",2)
	D QUEUE("REBLD",REXML,1,XFIRST-1) ; THE BEFORE
	D QUEUE("REBLD",REXML,XLAST+1,@REXML@(0)) ; THE REST
	I $G(MXMLDEBUG) D PARY("REBLD")
	D BUILD("REBLD","RTMP")
	K @REXML ; KILL WHAT WAS THERE
	D CP("RTMP",REXML) ; COPY IN THE RESULT
	K @OLD
	Q
	;
MISSING(IXML,OARY)	     ; SEARTH THROUGH INXLM AND PUT ANY @@X@@ VARS IN OARY
	; W "Reporting on the missing",!
	; W OARY
	I '$D(@IXML@(0)) D EN^DDIOL("MALFORMED XML PASSED TO MISSING") Q
	N I
	S @OARY@(0)=0 ; INITIALIZED MISSING COUNT
	F I=1:1:@IXML@(0)  D   ; LOOP THROUGH WHOLE ARRAY
	. I @IXML@(I)?.E1"@@".E D  ; MISSING VARIABLE HERE
	. . D PUSH^MXMLTMP1(OARY,$P(@IXML@(I),"@@",2)) ; ADD TO OUTARY
	. . Q
	Q
	;
MAP(IXML,INARY,OXML)	; SUBSTITUTE MULTIPLE @@X@@ VARS WITH VALUES IN INARY
	; ZEXCEPT: MXMLDEBUG
	; AND PUT THE RESULTS IN OXML
	N XCNT
	I '$D(IXML) D EN^DDIOL("MALFORMED XML PASSED TO MAP") Q
	I '$D(@IXML@(0)) D  ; INITIALIZE COUNT
	. S XCNT=$O(@IXML@(""),-1)
	E  S XCNT=@IXML@(0) ;COUNT
	I $O(@INARY@(""))="" D EN^DDIOL("EMPTY ARRAY PASSED TO MAP") Q
	N I,J,TNAM,TVAL,TSTR
	S @OXML@(0)=XCNT ; TOTAL LINES IN OUTPUT
	F I=1:1:XCNT  D   ; LOOP THROUGH WHOLE ARRAY
	. S @OXML@(I)=@IXML@(I) ; COPY THE LINE TO OUTPUT
	. I @OXML@(I)?.E1"@@".E D  ; IS THERE A VARIABLE HERE?
	. . S TSTR=$P(@IXML@(I),"@@",1) ; INIT TO PART BEFORE VARS
	. . F J=2:2:10  D  Q:$P(@IXML@(I),"@@",J+2)=""  ; QUIT IF NO MORE VARS
	. . . I $G(MXMLDEBUG) D EN^DDIOL("IN MAPPING LOOP: "_TSTR)
	. . . S TNAM=$P(@OXML@(I),"@@",J) ; EXTRACT THE VARIABLE NAME
	. . . S TVAL="@@"_$P(@IXML@(I),"@@",J)_"@@" ; DEFAULT UNCHANGED
	. . . I $D(@INARY@(TNAM))  D  ; IS THE VARIABLE IN THE MAP?
	. . . . I '$D(@INARY@(TNAM,"F")) D  ; NOT A SPECIAL FIELD
	. . . . . S TVAL=@INARY@(TNAM) ; PULL OUT MAPPED VALUE
	. . . . E   ; PROCESS A FILEMAN FIELD
	. . . S TVAL=$$SYMENC^MXMLUTL(TVAL) ;MAKE SURE THE VALUE IS XML SAFE
	. . . S TSTR=TSTR_TVAL_$P(@IXML@(I),"@@",J+1) ; ADD VAR AND PART AFTER
	. . S @OXML@(I)=TSTR ; COPY LINE WITH MAPPED VALUES
	. . I $G(MXMLDEBUG) D EN^DDIOL(TSTR)
	I $G(MXMLDEBUG) D EN^DDIOL("MAPPED")
	Q
	;
PARY(GLO,ZN)	      ;PRINT AN ARRAY
	; IF ZN=-1 NO LINE NUMBERS
	N I
	F I=1:1:@GLO@(0) D  ;
	. I $G(ZN)=-1 D EN^DDIOL(@GLO@(I))
	. E  D EN^DDIOL(I_" "_@GLO@(I))
	Q
	;
H2ARY(IARYRTN,IHASH,IPRE)	; CONVERT IHASH TO RETURN ARRAY
	; IPRE IS OPTIONAL PREFIX FOR THE ELEMENTS. USED FOR MUPTIPLES 1^"VAR"^VALUE
	I '$D(IPRE) S IPRE=""
	N H2I S H2I=""
	; W $O(@IHASH@(H2I)),!
	F  S H2I=$O(@IHASH@(H2I)) Q:H2I=""  D  ; FOR EACH ELEMENT OF THE HASH
	. I $QS(H2I,$QL(H2I))="M" D  Q  ; SPECIAL CASE FOR MULTIPLES
	. . ;W H2I_"^"_@IHASH@(H2I),!
	. . N IH,IHI,IH2,IH2A,IH3
	. . S IH=$NA(@IHASH@(H2I)) ;
	. . S IH2A=$O(@IH@("")) ; SKIP OVER MULTIPLE DISCRIPTOR
	. . S IH2=$NA(@IH@(IH2A)) ; PAST THE "M","DIRETIONS" FOR EXAMPLE
	. . S IHI="" ; INDEX INTO "M" MULTIPLES
	. . F  S IHI=$O(@IH2@(IHI)) Q:IHI=""  D  ; FOR EACH SUB-MULTIPLE
	. . . ; W @IH@(IHI)
	. . . S IH3=$NA(@IH2@(IHI))
	. . . ; W "HEY",IH3,!
	. . . D H2ARY(.IARYRTN,IH3,IPRE_";"_IHI) ; RECURSIVE CALL - INDENTED ELEMENTS
	. . ; W IH,!
	. . ; W "C0CZZ",!
	. . ; W $NA(@IHASH@(H2I)),!
	. . Q  ;
	. D PUSH^MXMLTMP1(IARYRTN,IPRE_"^"_H2I_"^"_@IHASH@(H2I))
	. ; W @IARYRTN@(0),!
	Q
	;
XVARS(XVRTN,XVIXML)	; RETURNS AN ARRAY XVRTN OF ALL UNIQUE VARIABLES
	; DEFINED IN INPUT XML XVIXML BY @@VAR@@
	; XVRTN AND XVIXML ARE PASSED BY NAME
	;
	N XVI,XVTMP,XVT
	F XVI=1:1:@XVIXML@(0) D  ; FOR ALL LINES OF THE XML
	. S XVT=@XVIXML@(XVI)
	. I XVT["@@" S XVTMP($P(XVT,"@@",2))=XVI
	D H2ARY(XVRTN,"XVTMP")
	Q
	;
DXVARS(DXIN)	;DISPLAY ALL VARIABLES IN A TEMPLATE
	N DVARS ; PUT VARIABLE NAME RESULTS IN ARRAY HERE
	D XVARS("DVARS",DXIN) ; PULL OUT VARS
	D PARY^MXMLTMPL("DVARS") ;AND DISPLAY THEM
	Q
	;
TEST	; Run all the test cases
	D TEST^MXMLTMPT QUIT
