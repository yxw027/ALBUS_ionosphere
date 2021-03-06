C	jma_igrf10.f
C	my hack of the IGRF magnetic field to just get a simple subroutine
C	call for the magnetic field strength, no derivatives, etc.
C	2005 Aug 25  James M Anderson  --JIVE  start
C                                        taken from igrf10.f, see comments below







c$$$      PROGRAM IGRF10
C
C     This is a program for synthesising geomagnetic field values from the 
C     International Geomagnetic Reference Field series of models as agreed
c     in Decmember 2004 by IAGA Working Group V-MOD. 
C     It is the 10th generation IGRF, ie the 9th revision. 
C     The main-field models for 1900.0, 1905.0,..1940.0 and 2005.0 are 
C     non-definitive, those for 1945.0, 1950.0,...2000.0 are definitive and
C     the secular-variation model for 2005.0 to 2010.0 is non-definitive.
C
C     Main-field models are to degree and order 10 (ie 120 coefficients)
C     for 1900.0-1995.0 and to 13 (ie 195 coefficients) for 2000.0 onwards. 
C     The predictive secular-variation model is to degree and order 8 (ie 80
C     coefficients).
C
C     Options include values at different locations at different
C     times (spot), values at same location at one year intervals
C     (time series), grid of values at one time (grid); geodetic or
C     geocentric coordinates, latitude & longitude entered as decimal
C     degrees or degrees & minutes (not in grid), choice of main field 
C     or secular variation or both (grid only).
C
c     Adapted from 8th generation version to include new maximum degree for
c     main-field models for 2000.0 and onwards and use WGS84 spheroid instead
c     of International Astronomical Union 1966 spheroid as recommended by IAGA
c     in July 2003. Reference radius remains as 6371.2 km - it is NOT the mean
c     radius (= 6371.0 km) but 6371.2 km is what is used in determining the
c     coefficients. Adaptation by Susan Macmillan, August 2003 (for 
c     9th generation) and December 2004.
c     1995.0 coefficients as published in igrf9coeffs.xls and igrf10coeffs.xls
c     used - (Kimmo Korhonen spotted 1 nT difference in 11 coefficients)
c     Susan Macmillan July 2005
C
c$$$      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
c$$$      CHARACTER*1 IA
c$$$      CHARACTER*11 TYPE
c$$$      CHARACTER*20 NAME
c$$$      CHARACTER*30 FNM
c$$$      DATA DTMN,DTMX/1900.0,2015.0/
c$$$C
c$$$C
c$$$      WRITE(6,*)
c$$$      WRITE(6,*)'******************************************************'
c$$$      WRITE(6,*)'*              IGRF SYNTHESIS PROGRAM                *'
c$$$      WRITE(6,*)'*                                                    *'
c$$$      WRITE(6,*)'* A program for the computation of geomagnetic       *'
c$$$      WRITE(6,*)'* field elements from the International Geomagnetic  *'
c$$$      WRITE(6,*)'* Reference Field (9th generation) as revised in     *'
c$$$      WRITE(6,*)'* December 2004 by the IAGA Working Group V-MOD.     *'
c$$$      WRITE(6,*)'*                                                    *'
c$$$      WRITE(6,*)'* It is valid for dates from 1900.0 to 2010.0,       *'
c$$$      WRITE(6,*)'* values up to 2015.0 will be computed but with      *'
c$$$      WRITE(6,*)'* reduced accuracy. Values for dates before 1945.0   *'
c$$$      WRITE(6,*)'* and after 2000.0 are non-definitive, otherwise the *'
c$$$      WRITE(6,*)'* values are definitive.                             *'
c$$$      WRITE(6,*)'*                                                    *'
c$$$      WRITE(6,*)'* Susan Macmillan          British Geological Survey *'
c$$$      WRITE(6,*)'*                     Chair IAGA Working Group V-MOD *'
c$$$      WRITE(6,*)'******************************************************'
c$$$      WRITE(6,*)
c$$$      WRITE(6,*)'Enter name of output file (30 characters maximum)'
c$$$      WRITE(6,*)'or press "Return" for output to screen'
c$$$      READ (5,991) FNM
c$$$  991 FORMAT (A30)
c$$$      IF (ICHAR(FNM(1:1)).EQ.32) THEN
c$$$       IU = 6
c$$$      ELSE
c$$$       IU = 2
c$$$       OPEN (UNIT = IU,FILE = FNM,STATUS = 'NEW')
c$$$      END IF
c$$$      FACT = 180.0/3.141592654
c$$$      NCOUNT = 0
c$$$C
c$$$   10 WRITE(6,*)'Enter value for coordinate system:'
c$$$      WRITE(6,*)
c$$$     1'1 - geodetic (shape of Earth is approximated by a spheroid)'
c$$$      WRITE(6,*)
c$$$     1'2 - geocentric (shape of Earth is approximated by a sphere)'
c$$$      READ (5,*) ITYPE
c$$$      IF (ITYPE.LT.1.OR.ITYPE.GT.2) GO TO 10
c$$$      IF (ITYPE.EQ.1) TYPE = ' geodetic  '
c$$$      IF (ITYPE.EQ.2) TYPE = ' geocentric'
c$$$C
c$$$   20 WRITE(6,*) 'Choose an option:'
c$$$      WRITE(6,*) '1 - values at one or more locations & dates'
c$$$      WRITE(6,*) '2 - values at yearly intervals at one location'
c$$$      WRITE(6,*) '3 - values on a latitude/longitude grid at one date'
c$$$      READ (5,*) IOPT
c$$$      IF(IOPT.LT.1.OR.IOPT.GT.3) GO TO 20
c$$$      IF (IOPT.EQ.3) GO TO 150
c$$$C
c$$$   30 WRITE(6,*)'Enter value for format of latitudes and longitudes:'
c$$$      WRITE(6,*)'1 - in degrees & minutes'
c$$$      WRITE(6,*)'2 - in decimal degrees'
c$$$      READ (5,*) IDM
c$$$      IF (IDM.LT.1.OR.IDM.GT.2) GO TO 30
c$$$      IF (NCOUNT.EQ.0) GOTO 50
c$$$C
c$$$   40 WRITE(6,*) 
c$$$     1'Do you want values for another date & position? (y/n)'
c$$$      READ (5,'(A1)') IA    
c$$$      IF (IA.NE.'Y'.AND.IA.NE.'y'.AND.IA.NE.'N'.AND.IA.NE.'n')
c$$$     1     GO TO 40
c$$$      IF(IA.EQ.'N'.OR.IA.EQ.'n') THEN
c$$$       WRITE(IU,928)
c$$$  928  FORMAT (' D is declination (+ve east)'/
c$$$     1          ' I is inclination (+ve down)'/
c$$$     2          ' H is horizontal intensity'/
c$$$     3          ' X is north component'/
c$$$     4          ' Y is east component'/
c$$$     5          ' Z is vertical component (+ve down)'/
c$$$     6          ' F is total intensity')
c$$$       WRITE(IU,929)
c$$$  929  FORMAT (/' SV is secular variation (annual rate of change)')
c$$$       IF (ITYPE.EQ.2) THEN
c$$$        WRITE(IU,*)
c$$$     1'These elements are relative to the geocentric coordinate system'
c$$$       ELSE
c$$$        WRITE(IU,*)
c$$$       ENDIF
c$$$       STOP
c$$$      ENDIF
c$$$C
c$$$   50 NCOUNT = 1
c$$$      IF (IOPT.NE.2) THEN
c$$$       WRITE(6,*) 'Enter date in years A.D.'
c$$$       READ (5,*) DATE
c$$$       IF (DATE.LT.DTMN.OR.DATE.GT.DTMX) GO TO 209
c$$$      ENDIF
c$$$
c$$$      IF(ITYPE.EQ.1) THEN
c$$$       WRITE(6,*) 'Enter altitude in km'
c$$$      ELSE  
c$$$       WRITE(6,*) 'Enter radial distance in km (>3485 km)'
c$$$      END IF
c$$$      READ (5,*) ALT
c$$$      IF (ITYPE.EQ.2.AND.ALT.LE.3485.0) GO TO 210
c$$$C
c$$$      IF (IDM.EQ.1) THEN
c$$$       WRITE(6,*) 'Enter latitude & longitude in degrees & minutes'
c$$$       WRITE(6,*) '(if either latitude or longitude is between -1'
c$$$       WRITE(6,*) 'and 0 degrees, enter the minutes as negative).'
c$$$       WRITE(6,*) 'Enter 4 integers' 
c$$$       READ (5,*) LTD,LTM,LND,LNM
c$$$       IF (LTD.LT.-90.OR.LTD.GT.90.OR.LTM.LE.-60.OR.LTM.GE.60) GO TO 204
c$$$       IF (LND.LT.-360.OR.LND.GT.360.OR.LNM.LE.-60.OR.LNM.GE.60)
c$$$     1    GO TO 205
c$$$       IF (LTM.LT.0.AND.LTD.NE.0) GO TO 204
c$$$       IF (LNM.LT.0.AND.LND.NE.0) GO TO 205
c$$$       CALL DMDDEC (LTD,LTM,XLT)
c$$$       CALL DMDDEC (LND,LNM,XLN)
c$$$      ELSE
c$$$       WRITE(6,*) 'Enter latitude & longitude in decimal degrees'
c$$$       READ (5,*) XLT,XLN
c$$$       IF (XLT.LT.-90.0.OR.XLT.GT.90.0) GO TO 202
c$$$       IF (XLN.LT.-360.0.OR.XLN.GT.360.0) GO TO 203
c$$$      ENDIF
c$$$C
c$$$      WRITE(*,*) 'Enter place name (20 characters maximum)'
c$$$      READ (*,'(A)') NAME
c$$$      CLT = 90.0 - XLT
c$$$      IF (CLT.LT.0.0.OR.CLT.GT.180.0) GO TO 204
c$$$      IF (XLN.LE.-360.0.OR.XLN.GE.360.0) GO TO 205
c$$$      IF (IOPT.EQ.2) GOTO 60
c$$$C
c$$$      CALL IGRF10SYN (0,DATE,ITYPE,ALT,CLT,XLN,X,Y,Z,F)
c$$$      D = FACT*ATAN2(Y,X)
c$$$      H = SQRT(X*X + Y*Y)
c$$$      S = FACT*ATAN2(Z,H)
c$$$      CALL DDECDM (D,IDEC,IDECM)
c$$$      CALL DDECDM (S,INC,INCM)
c$$$C
c$$$      CALL IGRF10SYN (1,DATE,ITYPE,ALT,CLT,XLN,DX,DY,DZ,F1)
c$$$      DD = (60.0*FACT*(X*DY - Y*DX))/(H*H)
c$$$      DH = (X*DX + Y*DY)/H
c$$$      DS = (60.0*FACT*(H*DZ - Z*DH))/(F*F)
c$$$      DF = (H*DH + Z*DZ)/F
c$$$C
c$$$      IF (IDM.EQ.1) THEN
c$$$       WRITE(IU,930) DATE,LTD,LTM,TYPE,LND,LNM,ALT,NAME
c$$$  930  FORMAT (1X,F8.3,' Lat',2I4,A11,' Long ',2I4,F10.3,' km ',A20)
c$$$      ELSE
c$$$       WRITE(IU,931) DATE,XLT,TYPE,XLN,ALT,NAME
c$$$  931  FORMAT (1X,F8.3,' Lat',F8.3,A11,' Long ',F8.3,F10.3,' km ',A20)
c$$$      ENDIF
c$$$C
c$$$      IDD = NINT(DD)
c$$$      WRITE(IU,937) IDEC,IDECM,IDD
c$$$  937 FORMAT (15X,'D =',I5,' deg',I4,' min',4X,'SV =',I8,' min/yr')
c$$$C
c$$$      IDS = NINT(DS)
c$$$      WRITE(IU,939) INC,INCM,IDS
c$$$  939 FORMAT (15X,'I =',I5,' deg',I4,' min',4X,'SV =',I8,' min/yr')
c$$$C
c$$$      IH = NINT(H)
c$$$      IDH = NINT(DH)
c$$$      WRITE(IU,941) IH,IDH
c$$$  941 FORMAT (15X,'H =',I8,' nT     ',5X,'SV =',I8,' nT/yr')
c$$$C
c$$$      IX = NINT(X)
c$$$      IDX = NINT(DX)
c$$$      WRITE(IU,943) IX,IDX
c$$$  943 FORMAT (15X,'X =',I8,' nT     ',5X,'SV =',I8,' nT/yr')
c$$$C
c$$$      IY = NINT(Y)
c$$$      IDY = NINT(DY)
c$$$      WRITE(IU,945) IY,IDY
c$$$  945 FORMAT (15X,'Y =',I8,' nT     ',5X,'SV =',I8,' nT/yr')
c$$$C
c$$$      IZ = NINT(Z)
c$$$      IDZ = NINT(DZ)
c$$$      WRITE(IU,947) IZ,IDZ
c$$$  947 FORMAT (15X,'Z =',I8,' nT     ',5X,'SV =',I8,' nT/yr')
c$$$C
c$$$      NF = NINT(F)
c$$$      IDF = NINT(DF)
c$$$      WRITE(IU,949) NF,IDF
c$$$  949 FORMAT (15X,'F =',I8,' nT     ',5X,'SV =',I8,' nT/yr'/)
c$$$C
c$$$      GO TO 40
c$$$C
c$$$   60 CONTINUE
c$$$C
c$$$C     SERIES OF VALUES AT ONE LOCATION...
c$$$C
c$$$      IF (IDM.EQ.1) THEN
c$$$       WRITE(IU,932) LTD,LTM,TYPE,LND,LNM,ALT,NAME
c$$$  932  FORMAT ('Lat',2I4,A11,'  Long ',2I4,F10.3,' km ',A20)
c$$$      ELSE
c$$$       WRITE(IU,933) XLT,TYPE,XLN,ALT,NAME
c$$$  933  FORMAT ('Lat',F8.3,A11,'  Long ',F8.3,F10.3,' km ',A20)
c$$$      ENDIF
c$$$      WRITE (IU,934)
c$$$  934 FORMAT (3X,'DATE',7X,'D',3X,'SV',6X,'I',2X,'SV',6X,'H',4X,'SV',
c$$$     17X,'X',4X,'SV',7X,'Y',4X,'SV',7X,'Z',4X,'SV',6X,'F',4X,'SV')
c$$$      IMX = DTMX - DTMN - 5
c$$$      DO 70 I = 1,IMX
c$$$      DATE = DTMN - 0.5 + I
c$$$      CALL IGRF10SYN (0,DATE,ITYPE,ALT,CLT,XLN,X,Y,Z,F)
c$$$      D = FACT*ATAN2(Y,X)
c$$$      H = SQRT(X*X + Y*Y)
c$$$      S = FACT*ATAN2(Z,H)
c$$$      IH = NINT(H)
c$$$      IX = NINT(X)
c$$$      IY = NINT(Y)
c$$$      IZ = NINT(Z)
c$$$      NF = NINT(F)
c$$$C
c$$$      CALL IGRF10SYN (1,DATE,ITYPE,ALT,CLT,XLN,DX,DY,DZ,F1)
c$$$      DD = (60.0*FACT*(X*DY - Y*DX))/(H*H)
c$$$      DH = (X*DX + Y*DY)/H
c$$$      DS = (60.0*FACT*(H*DZ - Z*DH))/(F*F)
c$$$      DF = (H*DH + Z*DZ)/F
c$$$      IDD = NINT(DD)
c$$$      IDH = NINT(DH)
c$$$      IDS = NINT(DS)
c$$$      IDX = NINT(DX)
c$$$      IDY = NINT(DY)
c$$$      IDZ = NINT(DZ)
c$$$      IDF = NINT(DF)
c$$$C
c$$$      WRITE(IU,935)
c$$$     1   DATE,D,IDD,S,IDS,IH,IDH,IX,IDX,IY,IDY,IZ,IDZ,NF,IDF
c$$$  935 FORMAT(1X,F6.1,F8.2,I5,F7.2,I4,I7,I6,3(I8,I6),I7,I6)
c$$$   70 CONTINUE
c$$$      IFL = 2
c$$$      GOTO 158
c$$$C
c$$$C     GRID OF VALUES...
c$$$C
c$$$  150 WRITE(6,*)'Enter value for MF/SV flag:'
c$$$      WRITE(6,*)'0 for main field (MF)'
c$$$      WRITE(6,*)'1 for secular variation (SV)'
c$$$      WRITE(6,*)'2 for both'
c$$$      WRITE(6,*)'9 to quit'
c$$$      READ (5,*) IFL
c$$$      IF (IFL.EQ.9) STOP
c$$$      IF (IFL.NE.0.AND.IFL.NE.1.AND.IFL.NE.2) GOTO 150
c$$$C
c$$$      WRITE(6,*) 'Enter initial value, final value & increment or'
c$$$      WRITE(6,*) 'decrement of latitude, in degrees & decimals'
c$$$      READ (5,*) XLTI,XLTF,XLTD
c$$$      LTI = NINT(1000.0*XLTI)
c$$$      LTF = NINT(1000.0*XLTF)
c$$$      LTD = NINT(1000.0*XLTD)
c$$$      WRITE(6,*) 'Enter initial value, final value & increment or'
c$$$      WRITE(6,*) 'decrement of longitude, in degrees & decimals'
c$$$      READ (5,*) XLNI,XLNF,XLND
c$$$      LNI = NINT(1000.0*XLNI)
c$$$      LNF = NINT(1000.0*XLNF)
c$$$      LND = NINT(1000.0*XLND)
c$$$      IF (LTI.LT.-90000.OR.LTI.GT.90000) GO TO 206
c$$$      IF (LTF.LT.-90000.OR.LTF.GT.90000) GO TO 206
c$$$      IF (LNI.LT.-360000.OR.LNI.GT.360000) GO TO 207
c$$$      IF (LNF.LT.-360000.OR.LNF.GT.360000) GO TO 207
c$$$   98 WRITE(6,*) 'Enter date in years A.D.'
c$$$      READ (5,*) DATE
c$$$      IF (DATE.LT.DTMN.OR.DATE.GT.DTMX) GO TO 209
c$$$      IF (ITYPE.EQ.1) THEN
c$$$       WRITE(6,*) 'Enter altitude in km'
c$$$      ELSE
c$$$       WRITE(6,*) 'Enter radial distance in km (>3485 km)'
c$$$      END IF
c$$$      READ (5,*) ALT
c$$$      IF (ITYPE.EQ.2.AND.ALT.LE.3485.0) GO TO 210
c$$$      WRITE(IU,958) DATE,ALT,TYPE
c$$$  958 FORMAT (' Date =',F9.3,5X,'Altitude =',F10.3,' km',5X,A11//
c$$$     1        '      Lat     Long',7X,'D',7X,'I',7X,'H',7X,'X',7X,'Y',
c$$$     2        7X,'Z',7X,'F')
c$$$C
c$$$      LT = LTI
c$$$  151 XLT = LT
c$$$      XLT = 0.001*XLT
c$$$      CLT = 90.0 - XLT
c$$$      IF (CLT.LT.-0.001.OR.CLT.GT.180.001) GO TO 202
c$$$      LN = LNI
c$$$  152 XLN = LN
c$$$      XLN = 0.001*XLN
c$$$      IF (XLN.LE.-360.0) XLN = XLN + 360.0
c$$$      IF (XLN.GE.360.0) XLN = XLN - 360.0
c$$$      CALL IGRF10SYN (0,DATE,ITYPE,ALT,CLT,XLN,X,Y,Z,F)
c$$$      D = FACT*ATAN2(Y,X)
c$$$      H = SQRT(X*X + Y*Y)
c$$$      S = FACT*ATAN2(Z,H)
c$$$      IH = NINT(H)
c$$$      IX = NINT(X)
c$$$      IY = NINT(Y)
c$$$      IZ = NINT(Z)
c$$$      NF = NINT(F)
c$$$      IF (IFL.EQ.0) GOTO 153
c$$$      CALL IGRF10SYN (1,DATE,ITYPE,ALT,CLT,XLN,DX,DY,DZ,F1)
c$$$      IDX = NINT(DX)
c$$$      IDY = NINT(DY)
c$$$      IDZ = NINT(DZ)
c$$$      DD = (60.0*FACT*(X*DY - Y*DX))/(H*H)
c$$$      IDD = NINT(DD)
c$$$      DH = (X*DX + Y*DY)/H
c$$$      IDH = NINT(DH)
c$$$      DS = (60.0*FACT*(H*DZ - Z*DH))/(F*F)
c$$$      IDS = NINT(DS)
c$$$      DF = (H*DH + Z*DZ)/F
c$$$      IDF = NINT(DF)
c$$$C
c$$$  153 CONTINUE
c$$$      IF (IFL.EQ.0) WRITE(IU,959) XLT,XLN,D,S,IH,IX,IY,IZ,NF
c$$$      IF (IFL.EQ.1) WRITE(IU,960) XLT,XLN,IDD,IDS,IDH,IDX,IDY,IDZ,IDF
c$$$      IF (IFL.EQ.2) THEN
c$$$       WRITE(IU,959) XLT,XLN,D,S,IH,IX,IY,IZ,NF
c$$$       WRITE(IU,961) IDD,IDS,IDH,IDX,IDY,IDZ,IDF
c$$$      ENDIF      
c$$$  959 FORMAT (2F9.3,2F8.2,5I8)
c$$$  960 FORMAT (2F9.3,7I8)
c$$$  961 FORMAT (14X,'SV: ',7I8)
c$$$C
c$$$  154 LN = LN + LND
c$$$      IF (LND.LT.0) GO TO 156
c$$$      IF (LN.LE.LNF) GO TO 152
c$$$  155 LT = LT + LTD
c$$$      IF (LTD.LT.0) GO TO 157
c$$$      IF (LT - LTF) 151,151,158
c$$$  156 IF (LN - LNF) 155,152,152
c$$$  157 IF (LT.GE.LTF) GO TO 151
c$$$  158 CONTINUE
c$$$      IF (IFL.EQ.0.OR.IFL.EQ.2) THEN
c$$$       WRITE(IU,962)
c$$$  962  FORMAT (/' D is declination in degrees (+ve east)'/
c$$$     1          ' I is inclination in degrees (+ve down)'/
c$$$     2          ' H is horizontal intensity in nT'/
c$$$     3          ' X is north component in nT'/
c$$$     4          ' Y is east component in nT'/
c$$$     5          ' Z is vertical component in nT (+ve down)'/
c$$$     6          ' F is total intensity in nT')
c$$$      IF (IFL.NE.0) WRITE(IU,963)
c$$$  963  FORMAT (' SV is secular variation (annual rate of change)'/
c$$$     1' Units for SV: minutes/yr (D & I); nT/yr (H,X,Y,Z & F)')
c$$$      IF (ITYPE.EQ.2) WRITE(IU,*)
c$$$     1'These elements are relative to the geocentric coordinate system'
c$$$      ELSE
c$$$       WRITE(IU,964)
c$$$  964  FORMAT (/' D is SV in declination in minutes/yr (+ve east)'/
c$$$     1          ' I is SV in inclination in minutes/yr (+ve down)'/
c$$$     2          ' H is SV in horizontal intensity in nT/yr'/
c$$$     3          ' X is SV in north component in nT/yr'/
c$$$     4          ' Y is SV in east component in nT/yr'/
c$$$     5          ' Z is SV in vertical component in nT/yr (+ve down)'/
c$$$     6          ' F is SV in total intensity in nT/yr')
c$$$      IF (ITYPE.EQ.2) WRITE(IU,*)
c$$$     1'These elements are relative to the geocentric coordinate system'
c$$$      ENDIF
c$$$  159 STOP
c$$$C
c$$$  209 WRITE(6,972) DATE
c$$$  972 FORMAT (' ***** Error *****'/' DATE =',F9.3,
c$$$     1        ' - out of range')
c$$$      STOP
c$$$C
c$$$  210 WRITE(6,973) ALT,ITYPE
c$$$  973 FORMAT (' ***** Error *****'/' A value of ALT =',F10.3,
c$$$     1        ' is not allowed when ITYPE =',I2)
c$$$      STOP
c$$$C
c$$$  202 WRITE(6,966) XLT
c$$$  966 FORMAT (' ***** Error *****'/' XLT =',F9.3,
c$$$     1        ' - out of range')
c$$$      STOP
c$$$C
c$$$  203 WRITE(6,967) XLN
c$$$  967 FORMAT (' ***** Error *****'/' XLN =',F10.3,
c$$$     1        ' - out of range')
c$$$      STOP
c$$$C
c$$$  204 WRITE(6,968) LTD,LTM
c$$$  968 FORMAT (' ***** Error *****'/' Latitude out of range',
c$$$     1        ' - LTD =',I6,5X,'LTM =',I4)
c$$$      STOP
c$$$C
c$$$  205 WRITE(6,969) LND,LNM
c$$$  969 FORMAT (' ***** Error *****'/' Longitude out of range',
c$$$     1        ' - LND =',I8,5X,'LNM =',I4)
c$$$      STOP
c$$$C
c$$$  206 WRITE(6,970) LTI,LTF
c$$$  970 FORMAT (' ***** Error *****'/
c$$$     1        ' Latitude limits of table out of range - LTI =',
c$$$     2        I6,5X,' LTF =',I6)
c$$$      STOP
c$$$C
c$$$  207 WRITE(6,971) LNI,LNF
c$$$  971 FORMAT (' ***** Error *****'/
c$$$     1        ' Longitude limits of table out of range - LNI =',
c$$$     2        I8,5X,' LNF =',I8)
c$$$      STOP
c$$$C
c$$$      END
c$$$C
c$$$      SUBROUTINE DMDDEC (I,M,X)
c$$$      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
c$$$      DE = I
c$$$      EM = M
c$$$      IF (I.LT.0) EM = -EM
c$$$      X = DE + EM/60.0
c$$$      RETURN
c$$$      END
c$$$C
c$$$      SUBROUTINE DDECDM (X,I,M)
c$$$      IMPLICIT DOUBLE PRECISION (A-H,O-Z)
c$$$      SIG = SIGN(1.1,X)
c$$$      DR = ABS(X)
c$$$      I = INT(DR)
c$$$      T = I
c$$$      M = NINT(60.*(DR - T))
c$$$      IF (M.EQ.60) THEN
c$$$       M = 0
c$$$       I = I + 1
c$$$      ENDIF
c$$$      ISIG = INT(SIG)
c$$$      IF (I.NE.0) THEN
c$$$       I = I * ISIG
c$$$      ELSE
c$$$       IF (M.NE.0) M = M * ISIG
c$$$      ENDIF
c$$$      RETURN
c$$$      END
c$$$  
c$$$      subroutine igrf10syn (isv,date,itype,alt,colat,elong,x,y,z,f)
c$$$c
c$$$c     This is a synthesis routine for the 10th generation IGRF as agreed 
c$$$c     in December 2004 by IAGA Working Group V-MOD. It is valid 1900.0 to
c$$$c     2010.0 inclusive. Values for dates from 1945.0 to 2000.0 inclusive are 
c$$$c     definitve, otherwise they are non-definitive.
c$$$c   INPUT
c$$$c     isv   = 0 if main-field values are required
c$$$c     isv   = 1 if secular variation values are required
c$$$c     date  = year A.D. Must be greater than or equal to 1900.0 and 
c$$$c             less than or equal to 2015.0. Warning message is given 
c$$$c             for dates greater than 2010.0. Must be double precision.
c$$$c     itype = 1 if geodetic (spheroid)
c$$$c     itype = 2 if geocentric (sphere)
c$$$c     alt   = height in km above sea level if itype = 1
c$$$c           = distance from centre of Earth in km if itype = 2 (>3485 km)
c$$$c     colat = colatitude (0-180)
c$$$c     elong = east-longitude (0-360)
c$$$c     alt, colat and elong must be double precision.
c$$$c   OUTPUT
c$$$c     x     = north component (nT) if isv = 0, nT/year if isv = 1
c$$$c     y     = east component (nT) if isv = 0, nT/year if isv = 1
c$$$c     z     = vertical component (nT) if isv = 0, nT/year if isv = 1
c$$$c     f     = total intensity (nT) if isv = 0, rubbish if isv = 1
c$$$c
c$$$c     To get the other geomagnetic elements (D, I, H and secular
c$$$c     variations dD, dH, dI and dF) use routines ptoc and ptocsv.
c$$$c
c$$$c     Adapted from 8th generation version to include new maximum degree for
c$$$c     main-field models for 2000.0 and onwards and use WGS84 spheroid instead
c$$$c     of International Astronomical Union 1966 spheroid as recommended by IAGA
c$$$c     in July 2003. Reference radius remains as 6371.2 km - it is NOT the mean
c$$$c     radius (= 6371.0 km) but 6371.2 km is what is used in determining the
c$$$c     coefficients. Adaptation by Susan Macmillan, August 2003 (for 
c$$$c     9th generation) and December 2004.
c$$$c     1995.0 coefficients as published in igrf9coeffs.xls and igrf10coeffs.xls
c$$$c     used - (Kimmo Korhonen spotted 1 nT difference in 11 coefficients)
c$$$c     Susan Macmillan July 2005
c$$$c
c$$$      implicit double precision (a-h,o-z)
c$$$      dimension gh(3060),g0(120),g1(120),g2(120),g3(120),g4(120),
c$$$     1          g5(120),g6(120),g7(120),g8(120),g9(120),ga(120),
c$$$     2          gb(120),gc(120),gd(120),ge(120),gf(120),gg(120),
c$$$     3          gi(120),gj(120),gk(195),gl(195),gm(195),gp(195),
c$$$     4          p(105),q(105),cl(13),sl(13)
c$$$      equivalence (g0,gh(  1)),(g1,gh(121)),(g2,gh(241)),(g3,gh(361)),
c$$$     1            (g4,gh(481)),(g5,gh(601)),(g6,gh(721)),(g7,gh(841)),
c$$$     2            (g8,gh(961)),(g9,gh(1081)),(ga,gh(1201)),
c$$$     3            (gb,gh(1321)),(gc,gh(1441)),(gd,gh(1561)),
c$$$     4            (ge,gh(1681)),(gf,gh(1801)),(gg,gh(1921)),
c$$$     5            (gi,gh(2041)),(gj,gh(2161)),(gk,gh(2281)),
c$$$     6            (gl,gh(2476)),(gm,gh(2671)),(gp,gh(2866))
c$$$c
c$$$      data g0/ -31543.,-2298., 5922., -677., 2905.,-1061.,  924., 1121., 1900
c$$$     1           1022.,-1469., -330., 1256.,    3.,  572.,  523.,  876., 1900
c$$$     2            628.,  195.,  660.,  -69., -361., -210.,  134.,  -75., 1900
c$$$     3           -184.,  328., -210.,  264.,   53.,    5.,  -33.,  -86., 1900
c$$$     4           -124.,  -16.,    3.,   63.,   61.,   -9.,  -11.,   83., 1900
c$$$     5           -217.,    2.,  -58.,  -35.,   59.,   36.,  -90.,  -69., 1900
c$$$     6             70.,  -55.,  -45.,    0.,  -13.,   34.,  -10.,  -41., 1900
c$$$     7             -1.,  -21.,   28.,   18.,  -12.,    6.,  -22.,   11., 1900
c$$$     8              8.,    8.,   -4.,  -14.,   -9.,    7.,    1.,  -13., 1900
c$$$     9              2.,    5.,   -9.,   16.,    5.,   -5.,    8.,  -18., 1900
c$$$     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1900
c$$$     b             -3.,    1.,   -2.,   -2.,    8.,    2.,   10.,   -1., 1900
c$$$     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1900
c$$$     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1900
c$$$     e              0.,   -2.,    2.,    4.,    2.,    0.,    0.,   -6./ 1900
c$$$      data g1/ -31464.,-2298., 5909., -728., 2928.,-1086., 1041., 1065., 1905
c$$$     1           1037.,-1494., -357., 1239.,   34.,  635.,  480.,  880., 1905
c$$$     2            643.,  203.,  653.,  -77., -380., -201.,  146.,  -65., 1905
c$$$     3           -192.,  328., -193.,  259.,   56.,   -1.,  -32.,  -93., 1905
c$$$     4           -125.,  -26.,   11.,   62.,   60.,   -7.,  -11.,   86., 1905
c$$$     5           -221.,    4.,  -57.,  -32.,   57.,   32.,  -92.,  -67., 1905
c$$$     6             70.,  -54.,  -46.,    0.,  -14.,   33.,  -11.,  -41., 1905
c$$$     7              0.,  -20.,   28.,   18.,  -12.,    6.,  -22.,   11., 1905
c$$$     8              8.,    8.,   -4.,  -15.,   -9.,    7.,    1.,  -13., 1905
c$$$     9              2.,    5.,   -8.,   16.,    5.,   -5.,    8.,  -18., 1905
c$$$     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1905
c$$$     b             -3.,    1.,   -2.,   -2.,    8.,    2.,   10.,    0., 1905
c$$$     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1905
c$$$     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1905
c$$$     e              0.,   -2.,    2.,    4.,    2.,    0.,    0.,   -6./ 1905
c$$$      data g2/ -31354.,-2297., 5898., -769., 2948.,-1128., 1176., 1000., 1910
c$$$     1           1058.,-1524., -389., 1223.,   62.,  705.,  425.,  884., 1910
c$$$     2            660.,  211.,  644.,  -90., -400., -189.,  160.,  -55., 1910
c$$$     3           -201.,  327., -172.,  253.,   57.,   -9.,  -33., -102., 1910
c$$$     4           -126.,  -38.,   21.,   62.,   58.,   -5.,  -11.,   89., 1910
c$$$     5           -224.,    5.,  -54.,  -29.,   54.,   28.,  -95.,  -65., 1910
c$$$     6             71.,  -54.,  -47.,    1.,  -14.,   32.,  -12.,  -40., 1910
c$$$     7              1.,  -19.,   28.,   18.,  -13.,    6.,  -22.,   11., 1910
c$$$     8              8.,    8.,   -4.,  -15.,   -9.,    6.,    1.,  -13., 1910
c$$$     9              2.,    5.,   -8.,   16.,    5.,   -5.,    8.,  -18., 1910
c$$$     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1910
c$$$     b             -3.,    1.,   -2.,   -2.,    8.,    2.,   10.,    0., 1910
c$$$     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1910
c$$$     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1910
c$$$     e              0.,   -2.,    2.,    4.,    2.,    0.,    0.,   -6./ 1910
c$$$      data g3/ -31212.,-2306., 5875., -802., 2956.,-1191., 1309.,  917., 1915
c$$$     1           1084.,-1559., -421., 1212.,   84.,  778.,  360.,  887., 1915
c$$$     2            678.,  218.,  631., -109., -416., -173.,  178.,  -51., 1915
c$$$     3           -211.,  327., -148.,  245.,   58.,  -16.,  -34., -111., 1915
c$$$     4           -126.,  -51.,   32.,   61.,   57.,   -2.,  -10.,   93., 1915
c$$$     5           -228.,    8.,  -51.,  -26.,   49.,   23.,  -98.,  -62., 1915
c$$$     6             72.,  -54.,  -48.,    2.,  -14.,   31.,  -12.,  -38., 1915
c$$$     7              2.,  -18.,   28.,   19.,  -15.,    6.,  -22.,   11., 1915
c$$$     8              8.,    8.,   -4.,  -15.,   -9.,    6.,    2.,  -13., 1915
c$$$     9              3.,    5.,   -8.,   16.,    6.,   -5.,    8.,  -18., 1915
c$$$     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1915
c$$$     b             -3.,    1.,   -2.,   -2.,    8.,    2.,   10.,    0., 1915
c$$$     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1915
c$$$     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1915
c$$$     e              0.,   -2.,    1.,    4.,    2.,    0.,    0.,   -6./ 1915
c$$$      data g4/ -31060.,-2317., 5845., -839., 2959.,-1259., 1407.,  823., 1920
c$$$     1           1111.,-1600., -445., 1205.,  103.,  839.,  293.,  889., 1920
c$$$     2            695.,  220.,  616., -134., -424., -153.,  199.,  -57., 1920
c$$$     3           -221.,  326., -122.,  236.,   58.,  -23.,  -38., -119., 1920
c$$$     4           -125.,  -62.,   43.,   61.,   55.,    0.,  -10.,   96., 1920
c$$$     5           -233.,   11.,  -46.,  -22.,   44.,   18., -101.,  -57., 1920
c$$$     6             73.,  -54.,  -49.,    2.,  -14.,   29.,  -13.,  -37., 1920
c$$$     7              4.,  -16.,   28.,   19.,  -16.,    6.,  -22.,   11., 1920
c$$$     8              7.,    8.,   -3.,  -15.,   -9.,    6.,    2.,  -14., 1920
c$$$     9              4.,    5.,   -7.,   17.,    6.,   -5.,    8.,  -19., 1920
c$$$     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1920
c$$$     b             -3.,    1.,   -2.,   -2.,    9.,    2.,   10.,    0., 1920
c$$$     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1920
c$$$     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1920
c$$$     e              0.,   -2.,    1.,    4.,    3.,    0.,    0.,   -6./ 1920
c$$$      data g5/ -30926.,-2318., 5817., -893., 2969.,-1334., 1471.,  728., 1925
c$$$     1           1140.,-1645., -462., 1202.,  119.,  881.,  229.,  891., 1925
c$$$     2            711.,  216.,  601., -163., -426., -130.,  217.,  -70., 1925
c$$$     3           -230.,  326.,  -96.,  226.,   58.,  -28.,  -44., -125., 1925
c$$$     4           -122.,  -69.,   51.,   61.,   54.,    3.,   -9.,   99., 1925
c$$$     5           -238.,   14.,  -40.,  -18.,   39.,   13., -103.,  -52., 1925
c$$$     6             73.,  -54.,  -50.,    3.,  -14.,   27.,  -14.,  -35., 1925
c$$$     7              5.,  -14.,   29.,   19.,  -17.,    6.,  -21.,   11., 1925
c$$$     8              7.,    8.,   -3.,  -15.,   -9.,    6.,    2.,  -14., 1925
c$$$     9              4.,    5.,   -7.,   17.,    7.,   -5.,    8.,  -19., 1925
c$$$     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1925
c$$$     b             -3.,    1.,   -2.,   -2.,    9.,    2.,   10.,    0., 1925
c$$$     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1925
c$$$     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1925
c$$$     e              0.,   -2.,    1.,    4.,    3.,    0.,    0.,   -6./ 1925
c$$$      data g6/ -30805.,-2316., 5808., -951., 2980.,-1424., 1517.,  644., 1930
c$$$     1           1172.,-1692., -480., 1205.,  133.,  907.,  166.,  896., 1930
c$$$     2            727.,  205.,  584., -195., -422., -109.,  234.,  -90., 1930
c$$$     3           -237.,  327.,  -72.,  218.,   60.,  -32.,  -53., -131., 1930
c$$$     4           -118.,  -74.,   58.,   60.,   53.,    4.,   -9.,  102., 1930
c$$$     5           -242.,   19.,  -32.,  -16.,   32.,    8., -104.,  -46., 1930
c$$$     6             74.,  -54.,  -51.,    4.,  -15.,   25.,  -14.,  -34., 1930
c$$$     7              6.,  -12.,   29.,   18.,  -18.,    6.,  -20.,   11., 1930
c$$$     8              7.,    8.,   -3.,  -15.,   -9.,    5.,    2.,  -14., 1930
c$$$     9              5.,    5.,   -6.,   18.,    8.,   -5.,    8.,  -19., 1930
c$$$     a              8.,   10.,  -20.,    1.,   14.,  -12.,    5.,   12., 1930
c$$$     b             -3.,    1.,   -2.,   -2.,    9.,    3.,   10.,    0., 1930
c$$$     c             -2.,   -2.,    2.,   -3.,   -4.,    2.,    2.,    1., 1930
c$$$     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1930
c$$$     e              0.,   -2.,    1.,    4.,    3.,    0.,    0.,   -6./ 1930
c$$$      data g7/ -30715.,-2306., 5812.,-1018., 2984.,-1520., 1550.,  586., 1935
c$$$     1           1206.,-1740., -494., 1215.,  146.,  918.,  101.,  903., 1935
c$$$     2            744.,  188.,  565., -226., -415.,  -90.,  249., -114., 1935
c$$$     3           -241.,  329.,  -51.,  211.,   64.,  -33.,  -64., -136., 1935
c$$$     4           -115.,  -76.,   64.,   59.,   53.,    4.,   -8.,  104., 1935
c$$$     5           -246.,   25.,  -25.,  -15.,   25.,    4., -106.,  -40., 1935
c$$$     6             74.,  -53.,  -52.,    4.,  -17.,   23.,  -14.,  -33., 1935
c$$$     7              7.,  -11.,   29.,   18.,  -19.,    6.,  -19.,   11., 1935
c$$$     8              7.,    8.,   -3.,  -15.,   -9.,    5.,    1.,  -15., 1935
c$$$     9              6.,    5.,   -6.,   18.,    8.,   -5.,    7.,  -19., 1935
c$$$     a              8.,   10.,  -20.,    1.,   15.,  -12.,    5.,   11., 1935
c$$$     b             -3.,    1.,   -3.,   -2.,    9.,    3.,   11.,    0., 1935
c$$$     c             -2.,   -2.,    2.,   -3.,   -4.,    2.,    2.,    1., 1935
c$$$     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1935
c$$$     e              0.,   -1.,    2.,    4.,    3.,    0.,    0.,   -6./ 1935
c$$$      data g8/ -30654.,-2292., 5821.,-1106., 2981.,-1614., 1566.,  528., 1940
c$$$     1           1240.,-1790., -499., 1232.,  163.,  916.,   43.,  914., 1940
c$$$     2            762.,  169.,  550., -252., -405.,  -72.,  265., -141., 1940
c$$$     3           -241.,  334.,  -33.,  208.,   71.,  -33.,  -75., -141., 1940
c$$$     4           -113.,  -76.,   69.,   57.,   54.,    4.,   -7.,  105., 1940
c$$$     5           -249.,   33.,  -18.,  -15.,   18.,    0., -107.,  -33., 1940
c$$$     6             74.,  -53.,  -52.,    4.,  -18.,   20.,  -14.,  -31., 1940
c$$$     7              7.,   -9.,   29.,   17.,  -20.,    5.,  -19.,   11., 1940
c$$$     8              7.,    8.,   -3.,  -14.,  -10.,    5.,    1.,  -15., 1940
c$$$     9              6.,    5.,   -5.,   19.,    9.,   -5.,    7.,  -19., 1940
c$$$     a              8.,   10.,  -21.,    1.,   15.,  -12.,    5.,   11., 1940
c$$$     b             -3.,    1.,   -3.,   -2.,    9.,    3.,   11.,    1., 1940
c$$$     c             -2.,   -2.,    2.,   -3.,   -4.,    2.,    2.,    1., 1940
c$$$     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1940
c$$$     e              0.,   -1.,    2.,    4.,    3.,    0.,    0.,   -6./ 1940
c$$$      data g9/ -30594.,-2285., 5810.,-1244., 2990.,-1702., 1578.,  477., 1945
c$$$     1           1282.,-1834., -499., 1255.,  186.,  913.,  -11.,  944., 1945
c$$$     2            776.,  144.,  544., -276., -421.,  -55.,  304., -178., 1945
c$$$     3           -253.,  346.,  -12.,  194.,   95.,  -20.,  -67., -142., 1945
c$$$     4           -119.,  -82.,   82.,   59.,   57.,    6.,    6.,  100., 1945
c$$$     5           -246.,   16.,  -25.,   -9.,   21.,  -16., -104.,  -39., 1945
c$$$     6             70.,  -40.,  -45.,    0.,  -18.,    0.,    2.,  -29., 1945
c$$$     7              6.,  -10.,   28.,   15.,  -17.,   29.,  -22.,   13., 1945
c$$$     8              7.,   12.,   -8.,  -21.,   -5.,  -12.,    9.,   -7., 1945
c$$$     9              7.,    2.,  -10.,   18.,    7.,    3.,    2.,  -11., 1945
c$$$     a              5.,  -21.,  -27.,    1.,   17.,  -11.,   29.,    3., 1945
c$$$     b             -9.,   16.,    4.,   -3.,    9.,   -4.,    6.,   -3., 1945
c$$$     c              1.,   -4.,    8.,   -3.,   11.,    5.,    1.,    1., 1945
c$$$     d              2.,  -20.,   -5.,   -1.,   -1.,   -6.,    8.,    6., 1945
c$$$     e             -1.,   -4.,   -3.,   -2.,    5.,    0.,   -2.,   -2./ 1945
c$$$      data ga/ -30554.,-2250., 5815.,-1341., 2998.,-1810., 1576.,  381., 1950
c$$$     1           1297.,-1889., -476., 1274.,  206.,  896.,  -46.,  954., 1950
c$$$     2            792.,  136.,  528., -278., -408.,  -37.,  303., -210., 1950
c$$$     3           -240.,  349.,    3.,  211.,  103.,  -20.,  -87., -147., 1950
c$$$     4           -122.,  -76.,   80.,   54.,   57.,   -1.,    4.,   99., 1950
c$$$     5           -247.,   33.,  -16.,  -12.,   12.,  -12., -105.,  -30., 1950
c$$$     6             65.,  -55.,  -35.,    2.,  -17.,    1.,    0.,  -40., 1950
c$$$     7             10.,   -7.,   36.,    5.,  -18.,   19.,  -16.,   22., 1950
c$$$     8             15.,    5.,   -4.,  -22.,   -1.,    0.,   11.,  -21., 1950
c$$$     9             15.,   -8.,  -13.,   17.,    5.,   -4.,   -1.,  -17., 1950
c$$$     a              3.,   -7.,  -24.,   -1.,   19.,  -25.,   12.,   10., 1950
c$$$     b              2.,    5.,    2.,   -5.,    8.,   -2.,    8.,    3., 1950
c$$$     c            -11.,    8.,   -7.,   -8.,    4.,   13.,   -1.,   -2., 1950
c$$$     d             13.,  -10.,   -4.,    2.,    4.,   -3.,   12.,    6., 1950
c$$$     e              3.,   -3.,    2.,    6.,   10.,   11.,    3.,    8./ 1950
c$$$      data gb/ -30500.,-2215., 5820.,-1440., 3003.,-1898., 1581.,  291., 1955
c$$$     1           1302.,-1944., -462., 1288.,  216.,  882.,  -83.,  958., 1955
c$$$     2            796.,  133.,  510., -274., -397.,  -23.,  290., -230., 1955
c$$$     3           -229.,  360.,   15.,  230.,  110.,  -23.,  -98., -152., 1955
c$$$     4           -121.,  -69.,   78.,   47.,   57.,   -9.,    3.,   96., 1955
c$$$     5           -247.,   48.,   -8.,  -16.,    7.,  -12., -107.,  -24., 1955
c$$$     6             65.,  -56.,  -50.,    2.,  -24.,   10.,   -4.,  -32., 1955
c$$$     7              8.,  -11.,   28.,    9.,  -20.,   18.,  -18.,   11., 1955
c$$$     8              9.,   10.,   -6.,  -15.,  -14.,    5.,    6.,  -23., 1955
c$$$     9             10.,    3.,   -7.,   23.,    6.,   -4.,    9.,  -13., 1955
c$$$     a              4.,    9.,  -11.,   -4.,   12.,   -5.,    7.,    2., 1955
c$$$     b              6.,    4.,   -2.,    1.,   10.,    2.,    7.,    2., 1955
c$$$     c             -6.,    5.,    5.,   -3.,   -5.,   -4.,   -1.,    0., 1955
c$$$     d              2.,   -8.,   -3.,   -2.,    7.,   -4.,    4.,    1., 1955
c$$$     e             -2.,   -3.,    6.,    7.,   -2.,   -1.,    0.,   -3./ 1955
c$$$      data gc/ -30421.,-2169., 5791.,-1555., 3002.,-1967., 1590.,  206., 1960
c$$$     1           1302.,-1992., -414., 1289.,  224.,  878., -130.,  957., 1960
c$$$     2            800.,  135.,  504., -278., -394.,    3.,  269., -255., 1960
c$$$     3           -222.,  362.,   16.,  242.,  125.,  -26., -117., -156., 1960
c$$$     4           -114.,  -63.,   81.,   46.,   58.,  -10.,    1.,   99., 1960
c$$$     5           -237.,   60.,   -1.,  -20.,   -2.,  -11., -113.,  -17., 1960
c$$$     6             67.,  -56.,  -55.,    5.,  -28.,   15.,   -6.,  -32., 1960
c$$$     7              7.,   -7.,   23.,   17.,  -18.,    8.,  -17.,   15., 1960
c$$$     8              6.,   11.,   -4.,  -14.,  -11.,    7.,    2.,  -18., 1960
c$$$     9             10.,    4.,   -5.,   23.,   10.,    1.,    8.,  -20., 1960
c$$$     a              4.,    6.,  -18.,    0.,   12.,   -9.,    2.,    1., 1960
c$$$     b              0.,    4.,   -3.,   -1.,    9.,   -2.,    8.,    3., 1960
c$$$     c              0.,   -1.,    5.,    1.,   -3.,    4.,    4.,    1., 1960
c$$$     d              0.,    0.,   -1.,    2.,    4.,   -5.,    6.,    1., 1960
c$$$     e              1.,   -1.,   -1.,    6.,    2.,    0.,    0.,   -7./ 1960
c$$$      data gd/ -30334.,-2119., 5776.,-1662., 2997.,-2016., 1594.,  114., 1965
c$$$     1           1297.,-2038., -404., 1292.,  240.,  856., -165.,  957., 1965
c$$$     2            804.,  148.,  479., -269., -390.,   13.,  252., -269., 1965
c$$$     3           -219.,  358.,   19.,  254.,  128.,  -31., -126., -157., 1965
c$$$     4            -97.,  -62.,   81.,   45.,   61.,  -11.,    8.,  100., 1965
c$$$     5           -228.,   68.,    4.,  -32.,    1.,   -8., -111.,   -7., 1965
c$$$     6             75.,  -57.,  -61.,    4.,  -27.,   13.,   -2.,  -26., 1965
c$$$     7              6.,   -6.,   26.,   13.,  -23.,    1.,  -12.,   13., 1965
c$$$     8              5.,    7.,   -4.,  -12.,  -14.,    9.,    0.,  -16., 1965
c$$$     9              8.,    4.,   -1.,   24.,   11.,   -3.,    4.,  -17., 1965
c$$$     a              8.,   10.,  -22.,    2.,   15.,  -13.,    7.,   10., 1965
c$$$     b             -4.,   -1.,   -5.,   -1.,   10.,    5.,   10.,    1., 1965
c$$$     c             -4.,   -2.,    1.,   -2.,   -3.,    2.,    2.,    1., 1965
c$$$     d             -5.,    2.,   -2.,    6.,    4.,   -4.,    4.,    0., 1965
c$$$     e              0.,   -2.,    2.,    3.,    2.,    0.,    0.,   -6./ 1965
c$$$      data ge/ -30220.,-2068., 5737.,-1781., 3000.,-2047., 1611.,   25., 1970
c$$$     1           1287.,-2091., -366., 1278.,  251.,  838., -196.,  952., 1970
c$$$     2            800.,  167.,  461., -266., -395.,   26.,  234., -279., 1970
c$$$     3           -216.,  359.,   26.,  262.,  139.,  -42., -139., -160., 1970
c$$$     4            -91.,  -56.,   83.,   43.,   64.,  -12.,   15.,  100., 1970
c$$$     5           -212.,   72.,    2.,  -37.,    3.,   -6., -112.,    1., 1970
c$$$     6             72.,  -57.,  -70.,    1.,  -27.,   14.,   -4.,  -22., 1970
c$$$     7              8.,   -2.,   23.,   13.,  -23.,   -2.,  -11.,   14., 1970
c$$$     8              6.,    7.,   -2.,  -15.,  -13.,    6.,   -3.,  -17., 1970
c$$$     9              5.,    6.,    0.,   21.,   11.,   -6.,    3.,  -16., 1970
c$$$     a              8.,   10.,  -21.,    2.,   16.,  -12.,    6.,   10., 1970
c$$$     b             -4.,   -1.,   -5.,    0.,   10.,    3.,   11.,    1., 1970
c$$$     c             -2.,   -1.,    1.,   -3.,   -3.,    1.,    2.,    1., 1970
c$$$     d             -5.,    3.,   -1.,    4.,    6.,   -4.,    4.,    0., 1970
c$$$     e              1.,   -1.,    0.,    3.,    3.,    1.,   -1.,   -4./ 1970
c$$$      data gf/ -30100.,-2013., 5675.,-1902., 3010.,-2067., 1632.,  -68., 1975
c$$$     1           1276.,-2144., -333., 1260.,  262.,  830., -223.,  946., 1975
c$$$     2            791.,  191.,  438., -265., -405.,   39.,  216., -288., 1975
c$$$     3           -218.,  356.,   31.,  264.,  148.,  -59., -152., -159., 1975
c$$$     4            -83.,  -49.,   88.,   45.,   66.,  -13.,   28.,   99., 1975
c$$$     5           -198.,   75.,    1.,  -41.,    6.,   -4., -111.,   11., 1975
c$$$     6             71.,  -56.,  -77.,    1.,  -26.,   16.,   -5.,  -14., 1975
c$$$     7             10.,    0.,   22.,   12.,  -23.,   -5.,  -12.,   14., 1975
c$$$     8              6.,    6.,   -1.,  -16.,  -12.,    4.,   -8.,  -19., 1975
c$$$     9              4.,    6.,    0.,   18.,   10.,  -10.,    1.,  -17., 1975
c$$$     a              7.,   10.,  -21.,    2.,   16.,  -12.,    7.,   10., 1975
c$$$     b             -4.,   -1.,   -5.,   -1.,   10.,    4.,   11.,    1., 1975
c$$$     c             -3.,   -2.,    1.,   -3.,   -3.,    1.,    2.,    1., 1975
c$$$     d             -5.,    3.,   -2.,    4.,    5.,   -4.,    4.,   -1., 1975
c$$$     e              1.,   -1.,    0.,    3.,    3.,    1.,   -1.,   -5./ 1975
c$$$      data gg/ -29992.,-1956., 5604.,-1997., 3027.,-2129., 1663., -200., 1980
c$$$     1           1281.,-2180., -336., 1251.,  271.,  833., -252.,  938., 1980
c$$$     2            782.,  212.,  398., -257., -419.,   53.,  199., -297., 1980
c$$$     3           -218.,  357.,   46.,  261.,  150.,  -74., -151., -162., 1980
c$$$     4            -78.,  -48.,   92.,   48.,   66.,  -15.,   42.,   93., 1980
c$$$     5           -192.,   71.,    4.,  -43.,   14.,   -2., -108.,   17., 1980
c$$$     6             72.,  -59.,  -82.,    2.,  -27.,   21.,   -5.,  -12., 1980
c$$$     7             16.,    1.,   18.,   11.,  -23.,   -2.,  -10.,   18., 1980
c$$$     8              6.,    7.,    0.,  -18.,  -11.,    4.,   -7.,  -22., 1980
c$$$     9              4.,    9.,    3.,   16.,    6.,  -13.,   -1.,  -15., 1980
c$$$     a              5.,   10.,  -21.,    1.,   16.,  -12.,    9.,    9., 1980
c$$$     b             -5.,   -3.,   -6.,   -1.,    9.,    7.,   10.,    2., 1980
c$$$     c             -6.,   -5.,    2.,   -4.,   -4.,    1.,    2.,    0., 1980
c$$$     d             -5.,    3.,   -2.,    6.,    5.,   -4.,    3.,    0., 1980
c$$$     e              1.,   -1.,    2.,    4.,    3.,    0.,    0.,   -6./ 1980
c$$$      data gi/ -29873.,-1905., 5500.,-2072., 3044.,-2197., 1687., -306., 1985
c$$$     1           1296.,-2208., -310., 1247.,  284.,  829., -297.,  936., 1985
c$$$     2            780.,  232.,  361., -249., -424.,   69.,  170., -297., 1985
c$$$     3           -214.,  355.,   47.,  253.,  150.,  -93., -154., -164., 1985
c$$$     4            -75.,  -46.,   95.,   53.,   65.,  -16.,   51.,   88., 1985
c$$$     5           -185.,   69.,    4.,  -48.,   16.,   -1., -102.,   21., 1985
c$$$     6             74.,  -62.,  -83.,    3.,  -27.,   24.,   -2.,   -6., 1985
c$$$     7             20.,    4.,   17.,   10.,  -23.,    0.,   -7.,   21., 1985
c$$$     8              6.,    8.,    0.,  -19.,  -11.,    5.,   -9.,  -23., 1985
c$$$     9              4.,   11.,    4.,   14.,    4.,  -15.,   -4.,  -11., 1985
c$$$     a              5.,   10.,  -21.,    1.,   15.,  -12.,    9.,    9., 1985
c$$$     b             -6.,   -3.,   -6.,   -1.,    9.,    7.,    9.,    1., 1985
c$$$     c             -7.,   -5.,    2.,   -4.,   -4.,    1.,    3.,    0., 1985
c$$$     d             -5.,    3.,   -2.,    6.,    5.,   -4.,    3.,    0., 1985
c$$$     e              1.,   -1.,    2.,    4.,    3.,    0.,    0.,   -6./ 1985
c$$$      data gj/ -29775.,-1848., 5406.,-2131., 3059.,-2279., 1686., -373., 1990
c$$$     1           1314.,-2239., -284., 1248.,  293.,  802., -352.,  939., 1990
c$$$     2            780.,  247.,  325., -240., -423.,   84.,  141., -299., 1990
c$$$     3           -214.,  353.,   46.,  245.,  154., -109., -153., -165., 1990
c$$$     4            -69.,  -36.,   97.,   61.,   65.,  -16.,   59.,   82., 1990
c$$$     5           -178.,   69.,    3.,  -52.,   18.,    1.,  -96.,   24., 1990
c$$$     6             77.,  -64.,  -80.,    2.,  -26.,   26.,    0.,   -1., 1990
c$$$     7             21.,    5.,   17.,    9.,  -23.,    0.,   -4.,   23., 1990
c$$$     8              5.,   10.,   -1.,  -19.,  -10.,    6.,  -12.,  -22., 1990
c$$$     9              3.,   12.,    4.,   12.,    2.,  -16.,   -6.,  -10., 1990
c$$$     a              4.,    9.,  -20.,    1.,   15.,  -12.,   11.,    9., 1990
c$$$     b             -7.,   -4.,   -7.,   -2.,    9.,    7.,    8.,    1., 1990
c$$$     c             -7.,   -6.,    2.,   -3.,   -4.,    2.,    2.,    1., 1990
c$$$     d             -5.,    3.,   -2.,    6.,    4.,   -4.,    3.,    0., 1990
c$$$     e              1.,   -2.,    3.,    3.,    3.,   -1.,    0.,   -6./ 1990
c$$$      data gk/ -29692.,-1784., 5306.,-2200., 3070.,-2366., 1681., -413., 1995
c$$$     1           1335.,-2267., -262., 1249.,  302.,  759., -427.,  940., 1995
c$$$     2            780.,  262.,  290., -236., -418.,   97.,  122., -306., 1995
c$$$     3           -214.,  352.,   46.,  235.,  165., -118., -143., -166., 1995
c$$$     4            -55.,  -17.,  107.,   68.,   67.,  -17.,   68.,   72., 1995
c$$$     5           -170.,   67.,   -1.,  -58.,   19.,    1.,  -93.,   36., 1995
c$$$     6             77.,  -72.,  -69.,    1.,  -25.,   28.,    4.,    5., 1995
c$$$     7             24.,    4.,   17.,    8.,  -24.,   -2.,   -6.,   25., 1995
c$$$     8              6.,   11.,   -6.,  -21.,   -9.,    8.,  -14.,  -23., 1995
c$$$     9              9.,   15.,    6.,   11.,   -5.,  -16.,   -7.,   -4., 1995
c$$$     a              4.,    9.,  -20.,    3.,   15.,  -10.,   12.,    8., 1995
c$$$     b             -6.,   -8.,   -8.,   -1.,    8.,   10.,    5.,   -2., 1995
c$$$     c             -8.,   -8.,    3.,   -3.,   -6.,    1.,    2.,    0., 1995
c$$$     d             -4.,    4.,   -1.,    5.,    4.,   -5.,    2.,   -1., 1995
c$$$     e              2.,   -2.,    5.,    1.,    1.,   -2.,    0.,   -7., 1995
c$$$     f           75*0./                                                  1995
c$$$      data gl/ -29619.4,-1728.2, 5186.1,-2267.7, 3068.4,-2481.6, 1670.9, 2000
c$$$     1           -458.0, 1339.6,-2288.0, -227.6, 1252.1,  293.4,  714.5, 2000
c$$$     2           -491.1,  932.3,  786.8,  272.6,  250.0, -231.9, -403.0, 2000
c$$$     3            119.8,  111.3, -303.8, -218.8,  351.4,   43.8,  222.3, 2000
c$$$     4            171.9, -130.4, -133.1, -168.6,  -39.3,  -12.9,  106.3, 2000
c$$$     5             72.3,   68.2,  -17.4,   74.2,   63.7, -160.9,   65.1, 2000
c$$$     6             -5.9,  -61.2,   16.9,    0.7,  -90.4,   43.8,   79.0, 2000
c$$$     7            -74.0,  -64.6,    0.0,  -24.2,   33.3,    6.2,    9.1, 2000
c$$$     8             24.0,    6.9,   14.8,    7.3,  -25.4,   -1.2,   -5.8, 2000
c$$$     9             24.4,    6.6,   11.9,   -9.2,  -21.5,   -7.9,    8.5, 2000
c$$$     a            -16.6,  -21.5,    9.1,   15.5,    7.0,    8.9,   -7.9, 2000
c$$$     b            -14.9,   -7.0,   -2.1,    5.0,    9.4,  -19.7,    3.0, 2000
c$$$     c             13.4,   -8.4,   12.5,    6.3,   -6.2,   -8.9,   -8.4, 2000
c$$$     d             -1.5,    8.4,    9.3,    3.8,   -4.3,   -8.2,   -8.2, 2000
c$$$     e              4.8,   -2.6,   -6.0,    1.7,    1.7,    0.0,   -3.1, 2000
c$$$     f              4.0,   -0.5,    4.9,    3.7,   -5.9,    1.0,   -1.2, 2000
c$$$     g              2.0,   -2.9,    4.2,    0.2,    0.3,   -2.2,   -1.1, 2000
c$$$     h             -7.4,    2.7,   -1.7,    0.1,   -1.9,    1.3,    1.5, 2000
c$$$     i             -0.9,   -0.1,   -2.6,    0.1,    0.9,   -0.7,   -0.7, 2000
c$$$     j              0.7,   -2.8,    1.7,   -0.9,    0.1,   -1.2,    1.2, 2000
c$$$     k             -1.9,    4.0,   -0.9,   -2.2,   -0.3,   -0.4,    0.2, 2000
c$$$     l              0.3,    0.9,    2.5,   -0.2,   -2.6,    0.9,    0.7, 2000
c$$$     m             -0.5,    0.3,    0.3,    0.0,   -0.3,    0.0,   -0.4, 2000
c$$$     n              0.3,   -0.1,   -0.9,   -0.2,   -0.4,   -0.4,    0.8, 2000
c$$$     o             -0.2,   -0.9,   -0.9,    0.3,    0.2,    0.1,    1.8, 2000
c$$$     p             -0.4,   -0.4,    1.3,   -1.0,   -0.4,   -0.1,    0.7, 2000
c$$$     q              0.7,   -0.4,    0.3,    0.3,    0.6,   -0.1,    0.3, 2000
c$$$     r              0.4,   -0.2,    0.0,   -0.5,    0.1,   -0.9/         2000
c$$$      data gm/ -29556.8,-1671.8, 5080.0,-2340.5, 3047.0,-2594.9, 1656.9, 2005
c$$$     1           -516.7, 1335.7,-2305.3, -200.4, 1246.8,  269.3,  674.4, 2005
c$$$     2           -524.5,  919.8,  798.2,  281.4,  211.5, -225.8, -379.5, 2005
c$$$     3            145.7,  100.2, -304.7, -227.6,  354.4,   42.7,  208.8, 2005
c$$$     4            179.8, -136.6, -123.0, -168.3,  -19.5,  -14.1,  103.6, 2005
c$$$     5             72.9,   69.6,  -20.2,   76.6,   54.7, -151.1,   63.7, 2005
c$$$     6            -15.0,  -63.4,   14.7,    0.0,  -86.4,   50.3,   79.8, 2005
c$$$     7            -74.4,  -61.4,   -1.4,  -22.5,   38.6,    6.9,   12.3, 2005
c$$$     8             25.4,    9.4,   10.9,    5.5,  -26.4,    2.0,   -4.8, 2005
c$$$     9             24.8,    7.7,   11.2,  -11.4,  -21.0,   -6.8,    9.7, 2005
c$$$     a            -18.0,  -19.8,   10.0,   16.1,    9.4,    7.7,  -11.4, 2005
c$$$     b            -12.8,   -5.0,   -0.1,    5.6,    9.8,  -20.1,    3.6, 2005
c$$$     c             12.9,   -7.0,   12.7,    5.0,   -6.7,  -10.8,   -8.1, 2005
c$$$     d             -1.3,    8.1,    8.7,    2.9,   -6.7,   -7.9,   -9.2, 2005
c$$$     e              5.9,   -2.2,   -6.3,    2.4,    1.6,    0.2,   -2.5, 2005
c$$$     f              4.4,   -0.1,    4.7,    3.0,   -6.5,    0.3,   -1.0, 2005
c$$$     g              2.1,   -3.4,    3.9,   -0.9,   -0.1,   -2.3,   -2.2, 2005
c$$$     h             -8.0,    2.9,   -1.6,    0.3,   -1.7,    1.4,    1.5, 2005
c$$$     i             -0.7,   -0.2,   -2.4,    0.2,    0.9,   -0.7,   -0.6, 2005
c$$$     j              0.5,   -2.7,    1.8,   -1.0,    0.1,   -1.5,    1.0, 2005
c$$$     k             -2.0,    4.1,   -1.4,   -2.2,   -0.3,   -0.5,    0.3, 2005
c$$$     l              0.3,    0.9,    2.3,   -0.4,   -2.7,    1.0,    0.6, 2005
c$$$     m             -0.4,    0.4,    0.5,    0.0,   -0.3,    0.0,   -0.4, 2005
c$$$     n              0.3,    0.0,   -0.8,   -0.4,   -0.4,    0.0,    1.0, 2005
c$$$     o             -0.2,   -0.9,   -0.7,    0.3,    0.3,    0.3,    1.7, 2005
c$$$     p             -0.4,   -0.5,    1.2,   -1.0,   -0.4,    0.0,    0.7, 2005
c$$$     q              0.7,   -0.3,    0.2,    0.4,    0.6,   -0.1,    0.4, 2005
c$$$     r              0.4,   -0.2,   -0.1,   -0.5,   -0.3,   -1.0/         2005
c$$$      data gp/     8.8,  10.8, -21.3, -15.0,  -6.9, -23.3,  -1.0, -14.0, 2007
c$$$     1            -0.3,  -3.1,   5.4,  -0.9,  -6.5,  -6.8,  -2.0,  -2.5, 2007
c$$$     2             2.8,   2.0,  -7.1,   1.8,   5.9,   5.6,  -3.2,   0.0, 2007
c$$$     3            -2.6,   0.4,   0.1,  -3.0,   1.8,  -1.2,   2.0,   0.2, 2007
c$$$     4             4.5,  -0.6,  -1.0,  -0.8,   0.2,  -0.4,  -0.2,  -1.9, 2007
c$$$     5             2.1,  -0.4,  -2.1,  -0.4,  -0.4,  -0.2,   1.3,   0.9, 2007
c$$$     6            -0.4,   0.0,   0.8,  -0.2,   0.4,   1.1,   0.1,   0.6, 2007
c$$$     7             0.2,   0.4,  -0.9,  -0.5,  -0.3,   0.9,   0.3,  -0.2, 2007
c$$$     8             0.2,  -0.2,  -0.2,   0.2,   0.2,   0.2,  -0.2,   0.4, 2007
c$$$     9             0.2,   0.2,   0.5,  -0.3,  -0.7,   0.5,   0.5,   0.4, 2007
c$$$     a         115*0.0/                                                  2007
c$$$c
c$$$c     set initial values
c$$$c
c$$$      x     = 0.0
c$$$      y     = 0.0
c$$$      z     = 0.0
c$$$      if (date.lt.1900.0.or.date.gt.2015.0) go to 11
c$$$      if (date.gt.2010.0) write (6,960) date
c$$$  960 format (/' This version of the IGRF is intended for use up',
c$$$     1        ' to 2010.0.'/' values for',f9.3,' will be computed',
c$$$     2        ' but may be of reduced accuracy'/)
c$$$      if (date.ge.2005.0) go to 1
c$$$      t     = 0.2*(date - 1900.0)                                             
c$$$      ll    = t
c$$$      one   = ll
c$$$      t     = t - one
c$$$      if (date.lt.1995.0) then
c$$$       nmx   = 10
c$$$       nc    = nmx*(nmx+2)
c$$$       ll    = nc*ll
c$$$       kmx   = (nmx+1)*(nmx+2)/2
c$$$      else
c$$$       nmx   = 13
c$$$       nc    = nmx*(nmx+2)
c$$$       ll    = 0.2*(date - 1995.0)
c$$$       ll    = 120*19 + nc*ll
c$$$       kmx   = (nmx+1)*(nmx+2)/2
c$$$      endif
c$$$      tc    = 1.0 - t
c$$$      if (isv.eq.1) then
c$$$       tc = -0.2
c$$$       t = 0.2
c$$$      end if
c$$$      go to 2
c$$$c
c$$$    1 t     = date - 2005.0
c$$$      tc    = 1.0
c$$$      if (isv.eq.1) then
c$$$       t = 1.0
c$$$       tc = 0.0
c$$$      end if
c$$$      ll    = 2670
c$$$      nmx   = 13
c$$$      nc    = nmx*(nmx+2)
c$$$      kmx   = (nmx+1)*(nmx+2)/2
c$$$    2 r     = alt
c$$$      one   = colat*0.017453292
c$$$      ct    = cos(one)
c$$$      st    = sin(one)
c$$$      one   = elong*0.017453292
c$$$      cl(1) = cos(one)
c$$$      sl(1) = sin(one)
c$$$      cd    = 1.0
c$$$      sd    = 0.0
c$$$      l     = 1
c$$$      m     = 1
c$$$      n     = 0
c$$$      if (itype.eq.2) go to 3
c$$$c
c$$$c     conversion from geodetic to geocentric coordinates 
c$$$c     (using the WGS84 spheroid)
c$$$c
c$$$      a2    = 40680631.6
c$$$      b2    = 40408296.0
c$$$      one   = a2*st*st
c$$$      two   = b2*ct*ct
c$$$      three = one + two
c$$$      rho   = sqrt(three)
c$$$      r     = sqrt(alt*(alt + 2.0*rho) + (a2*one + b2*two)/three)
c$$$      cd    = (alt + rho)/r
c$$$      sd    = (a2 - b2)/rho*ct*st/r
c$$$      one   = ct
c$$$      ct    = ct*cd -  st*sd
c$$$      st    = st*cd + one*sd
c$$$c
c$$$    3 ratio = 6371.2/r
c$$$      rr    = ratio*ratio
c$$$c
c$$$c     computation of Schmidt quasi-normal coefficients p and x(=q)
c$$$c
c$$$      p(1)  = 1.0
c$$$      p(3)  = st
c$$$      q(1)  = 0.0
c$$$      q(3)  =  ct
c$$$      do 10 k=2,kmx                                                       
c$$$      if (n.ge.m) go to 4
c$$$      m     = 0
c$$$      n     = n + 1
c$$$      rr    = rr*ratio
c$$$      fn    = n
c$$$      gn    = n - 1
c$$$    4 fm    = m
c$$$      if (m.ne.n) go to 5
c$$$      if (k.eq.3) go to 6
c$$$      one   = sqrt(1.0 - 0.5/fm)
c$$$      j     = k - n - 1
c$$$      p(k)  = one*st*p(j)
c$$$      q(k)  = one*(st*q(j) + ct*p(j))
c$$$      cl(m) = cl(m-1)*cl(1) - sl(m-1)*sl(1)
c$$$      sl(m) = sl(m-1)*cl(1) + cl(m-1)*sl(1)
c$$$      go to 6                                                           
c$$$    5 gmm    = m*m
c$$$      one   = sqrt(fn*fn - gmm)
c$$$      two   = sqrt(gn*gn - gmm)/one
c$$$      three = (fn + gn)/one
c$$$      i     = k - n
c$$$      j     = i - n + 1
c$$$      p(k)  = three*ct*p(i) - two*p(j)
c$$$      q(k)  = three*(ct*q(i) - st*p(i)) - two*q(j)
c$$$c
c$$$c     synthesis of x, y and z in geocentric coordinates
c$$$c
c$$$    6 lm    = ll + l
c$$$      one   = (tc*gh(lm) + t*gh(lm+nc))*rr                                     
c$$$      if (m.eq.0) go to 9                                                      
c$$$      two   = (tc*gh(lm+1) + t*gh(lm+nc+1))*rr
c$$$      three = one*cl(m) + two*sl(m)
c$$$      x     = x + three*q(k)
c$$$      z     = z - (fn + 1.0)*three*p(k)
c$$$      if (st.eq.0.0) go to 7
c$$$      y     = y + (one*sl(m) - two*cl(m))*fm*p(k)/st
c$$$      go to 8
c$$$    7 y     = y + (one*sl(m) - two*cl(m))*q(k)*ct
c$$$    8 l     = l + 2
c$$$      go to 10
c$$$    9 x     = x + one*q(k)
c$$$      z     = z - (fn + 1.0)*one*p(k)
c$$$      l     = l + 1
c$$$   10 m     = m + 1
c$$$c
c$$$c     conversion to coordinate system specified by itype
c$$$c
c$$$      one   = x
c$$$      x     = x*cd +   z*sd
c$$$      z     = z*cd - one*sd
c$$$      f     = sqrt(x*x + y*y + z*z)
c$$$c
c$$$      return
c$$$c
c$$$c     error return if date out of bounds
c$$$c
c$$$   11 f     = 1.0d8
c$$$      write (6,961) date
c$$$  961 format (/' This subroutine will not work with a date of',
c$$$     1        f9.3,'.  Date must be in the range 1900.0.ge.date',
c$$$     2        '.le.2015.0.  On return f = 1.0d8., x = y = z = 0.')
c$$$      return
c$$$      end
c$$$
c$$$









      subroutine jma_igrf10syn (date,radius,clatit,slatit,
     &     clongi,slongi,x,y,z)
C_TITLE jma_igrf10syn --get the magnetic field at some time and place
      implicit double precision (a-h,o-z)

C_ARGS  TYPE           VARIABLE I/O DESCRIPTION
	double precision date  ! I  time (years AD)

        double precision radius! I  the position radius, in meters
        double precision clatit! I  the cos(latitude, in radians)
        double precision slatit! I  the sin(latitude, in radians)
	double precision clongi! I  the cos(longitude, in radians)
	double precision slongi! I  the sin(longitude, in radians)
C                                   only geocentric coordinates are supported

        double precision x     ! O  the magnetic field in the x direction in T
        double precision y     ! O  the magnetic field in the y direction in T
        double precision z     ! O  the magnetic field in the z direction in T
C	                            the directions are x--local North on surface
C                                                      y--local East on surface
C                                                      z--local down

C_USER  any user input?

C_VARS  TYPE           VARIABLE I/O DESCRIPTION
C     put include and common stuff here
        include 'logicuni.inc'

C_DESC  full description of program

C_FILE  files used and logical units used

C_LIMS  design limitations

C_BUGS  known bugs

C_CALL  list of calls

C_KEYS  

C_HIST  DATE NAME PLACE INFO
C     2005 Sep 02  James M Anderson  --JIVE  modify slightly for PIM use

C_END


c
c     This is a synthesis routine for the 10th generation IGRF as agreed 
c     in December 2004 by IAGA Working Group V-MOD. It is valid 1900.0 to
c     2010.0 inclusive. Values for dates from 1945.0 to 2000.0 inclusive are 
c     definitve, otherwise they are non-definitive.
c   INPUT
c     isv   = 0 if main-field values are required
c     isv   = 1 if secular variation values are required
c     date  = year A.D. Must be greater than or equal to 1900.0 and 
c             less than or equal to 2015.0. Warning message is given 
c             for dates greater than 2010.0. Must be double precision.
c     itype = 1 if geodetic (spheroid)
c     itype = 2 if geocentric (sphere)
c     alt   = height in km above sea level if itype = 1
c           = distance from centre of Earth in km if itype = 2 (>3485 km)
c     colat = colatitude (0-180)
c     elong = east-longitude (0-360)
c     alt, colat and elong must be double precision.
c   OUTPUT
c     x     = north component (nT) if isv = 0, nT/year if isv = 1
c     y     = east component (nT) if isv = 0, nT/year if isv = 1
c     z     = vertical component (nT) if isv = 0, nT/year if isv = 1
c     f     = total intensity (nT) if isv = 0, rubbish if isv = 1
c
c     To get the other geomagnetic elements (D, I, H and secular
c     variations dD, dH, dI and dF) use routines ptoc and ptocsv.
c
c     Adapted from 8th generation version to include new maximum degree for
c     main-field models for 2000.0 and onwards and use WGS84 spheroid instead
c     of International Astronomical Union 1966 spheroid as recommended by IAGA
c     in July 2003. Reference radius remains as 6371.2 km - it is NOT the mean
c     radius (= 6371.0 km) but 6371.2 km is what is used in determining the
c     coefficients. Adaptation by Susan Macmillan, August 2003 (for 
c     9th generation) and December 2004.
c     1995.0 coefficients as published in igrf9coeffs.xls and igrf10coeffs.xls
c     used - (Kimmo Korhonen spotted 1 nT difference in 11 coefficients)
c     Susan Macmillan July 2005
c
      dimension gh(3060),g0(120),g1(120),g2(120),g3(120),g4(120),
     1          g5(120),g6(120),g7(120),g8(120),g9(120),ga(120),
     2          gb(120),gc(120),gd(120),ge(120),gf(120),gg(120),
     3          gi(120),gj(120),gk(195),gl(195),gm(195),gp(195),
     4          p(105),q(105),cl(13),sl(13)
      equivalence (g0,gh(  1)),(g1,gh(121)),(g2,gh(241)),(g3,gh(361)),
     1            (g4,gh(481)),(g5,gh(601)),(g6,gh(721)),(g7,gh(841)),
     2            (g8,gh(961)),(g9,gh(1081)),(ga,gh(1201)),
     3            (gb,gh(1321)),(gc,gh(1441)),(gd,gh(1561)),
     4            (ge,gh(1681)),(gf,gh(1801)),(gg,gh(1921)),
     5            (gi,gh(2041)),(gj,gh(2161)),(gk,gh(2281)),
     6            (gl,gh(2476)),(gm,gh(2671)),(gp,gh(2866))
c
      data g0/ -31543.,-2298., 5922., -677., 2905.,-1061.,  924., 1121., 1900
     1           1022.,-1469., -330., 1256.,    3.,  572.,  523.,  876., 1900
     2            628.,  195.,  660.,  -69., -361., -210.,  134.,  -75., 1900
     3           -184.,  328., -210.,  264.,   53.,    5.,  -33.,  -86., 1900
     4           -124.,  -16.,    3.,   63.,   61.,   -9.,  -11.,   83., 1900
     5           -217.,    2.,  -58.,  -35.,   59.,   36.,  -90.,  -69., 1900
     6             70.,  -55.,  -45.,    0.,  -13.,   34.,  -10.,  -41., 1900
     7             -1.,  -21.,   28.,   18.,  -12.,    6.,  -22.,   11., 1900
     8              8.,    8.,   -4.,  -14.,   -9.,    7.,    1.,  -13., 1900
     9              2.,    5.,   -9.,   16.,    5.,   -5.,    8.,  -18., 1900
     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1900
     b             -3.,    1.,   -2.,   -2.,    8.,    2.,   10.,   -1., 1900
     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1900
     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1900
     e              0.,   -2.,    2.,    4.,    2.,    0.,    0.,   -6./ 1900
      data g1/ -31464.,-2298., 5909., -728., 2928.,-1086., 1041., 1065., 1905
     1           1037.,-1494., -357., 1239.,   34.,  635.,  480.,  880., 1905
     2            643.,  203.,  653.,  -77., -380., -201.,  146.,  -65., 1905
     3           -192.,  328., -193.,  259.,   56.,   -1.,  -32.,  -93., 1905
     4           -125.,  -26.,   11.,   62.,   60.,   -7.,  -11.,   86., 1905
     5           -221.,    4.,  -57.,  -32.,   57.,   32.,  -92.,  -67., 1905
     6             70.,  -54.,  -46.,    0.,  -14.,   33.,  -11.,  -41., 1905
     7              0.,  -20.,   28.,   18.,  -12.,    6.,  -22.,   11., 1905
     8              8.,    8.,   -4.,  -15.,   -9.,    7.,    1.,  -13., 1905
     9              2.,    5.,   -8.,   16.,    5.,   -5.,    8.,  -18., 1905
     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1905
     b             -3.,    1.,   -2.,   -2.,    8.,    2.,   10.,    0., 1905
     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1905
     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1905
     e              0.,   -2.,    2.,    4.,    2.,    0.,    0.,   -6./ 1905
      data g2/ -31354.,-2297., 5898., -769., 2948.,-1128., 1176., 1000., 1910
     1           1058.,-1524., -389., 1223.,   62.,  705.,  425.,  884., 1910
     2            660.,  211.,  644.,  -90., -400., -189.,  160.,  -55., 1910
     3           -201.,  327., -172.,  253.,   57.,   -9.,  -33., -102., 1910
     4           -126.,  -38.,   21.,   62.,   58.,   -5.,  -11.,   89., 1910
     5           -224.,    5.,  -54.,  -29.,   54.,   28.,  -95.,  -65., 1910
     6             71.,  -54.,  -47.,    1.,  -14.,   32.,  -12.,  -40., 1910
     7              1.,  -19.,   28.,   18.,  -13.,    6.,  -22.,   11., 1910
     8              8.,    8.,   -4.,  -15.,   -9.,    6.,    1.,  -13., 1910
     9              2.,    5.,   -8.,   16.,    5.,   -5.,    8.,  -18., 1910
     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1910
     b             -3.,    1.,   -2.,   -2.,    8.,    2.,   10.,    0., 1910
     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1910
     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1910
     e              0.,   -2.,    2.,    4.,    2.,    0.,    0.,   -6./ 1910
      data g3/ -31212.,-2306., 5875., -802., 2956.,-1191., 1309.,  917., 1915
     1           1084.,-1559., -421., 1212.,   84.,  778.,  360.,  887., 1915
     2            678.,  218.,  631., -109., -416., -173.,  178.,  -51., 1915
     3           -211.,  327., -148.,  245.,   58.,  -16.,  -34., -111., 1915
     4           -126.,  -51.,   32.,   61.,   57.,   -2.,  -10.,   93., 1915
     5           -228.,    8.,  -51.,  -26.,   49.,   23.,  -98.,  -62., 1915
     6             72.,  -54.,  -48.,    2.,  -14.,   31.,  -12.,  -38., 1915
     7              2.,  -18.,   28.,   19.,  -15.,    6.,  -22.,   11., 1915
     8              8.,    8.,   -4.,  -15.,   -9.,    6.,    2.,  -13., 1915
     9              3.,    5.,   -8.,   16.,    6.,   -5.,    8.,  -18., 1915
     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1915
     b             -3.,    1.,   -2.,   -2.,    8.,    2.,   10.,    0., 1915
     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1915
     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1915
     e              0.,   -2.,    1.,    4.,    2.,    0.,    0.,   -6./ 1915
      data g4/ -31060.,-2317., 5845., -839., 2959.,-1259., 1407.,  823., 1920
     1           1111.,-1600., -445., 1205.,  103.,  839.,  293.,  889., 1920
     2            695.,  220.,  616., -134., -424., -153.,  199.,  -57., 1920
     3           -221.,  326., -122.,  236.,   58.,  -23.,  -38., -119., 1920
     4           -125.,  -62.,   43.,   61.,   55.,    0.,  -10.,   96., 1920
     5           -233.,   11.,  -46.,  -22.,   44.,   18., -101.,  -57., 1920
     6             73.,  -54.,  -49.,    2.,  -14.,   29.,  -13.,  -37., 1920
     7              4.,  -16.,   28.,   19.,  -16.,    6.,  -22.,   11., 1920
     8              7.,    8.,   -3.,  -15.,   -9.,    6.,    2.,  -14., 1920
     9              4.,    5.,   -7.,   17.,    6.,   -5.,    8.,  -19., 1920
     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1920
     b             -3.,    1.,   -2.,   -2.,    9.,    2.,   10.,    0., 1920
     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1920
     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1920
     e              0.,   -2.,    1.,    4.,    3.,    0.,    0.,   -6./ 1920
      data g5/ -30926.,-2318., 5817., -893., 2969.,-1334., 1471.,  728., 1925
     1           1140.,-1645., -462., 1202.,  119.,  881.,  229.,  891., 1925
     2            711.,  216.,  601., -163., -426., -130.,  217.,  -70., 1925
     3           -230.,  326.,  -96.,  226.,   58.,  -28.,  -44., -125., 1925
     4           -122.,  -69.,   51.,   61.,   54.,    3.,   -9.,   99., 1925
     5           -238.,   14.,  -40.,  -18.,   39.,   13., -103.,  -52., 1925
     6             73.,  -54.,  -50.,    3.,  -14.,   27.,  -14.,  -35., 1925
     7              5.,  -14.,   29.,   19.,  -17.,    6.,  -21.,   11., 1925
     8              7.,    8.,   -3.,  -15.,   -9.,    6.,    2.,  -14., 1925
     9              4.,    5.,   -7.,   17.,    7.,   -5.,    8.,  -19., 1925
     a              8.,   10.,  -20.,    1.,   14.,  -11.,    5.,   12., 1925
     b             -3.,    1.,   -2.,   -2.,    9.,    2.,   10.,    0., 1925
     c             -2.,   -1.,    2.,   -3.,   -4.,    2.,    2.,    1., 1925
     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1925
     e              0.,   -2.,    1.,    4.,    3.,    0.,    0.,   -6./ 1925
      data g6/ -30805.,-2316., 5808., -951., 2980.,-1424., 1517.,  644., 1930
     1           1172.,-1692., -480., 1205.,  133.,  907.,  166.,  896., 1930
     2            727.,  205.,  584., -195., -422., -109.,  234.,  -90., 1930
     3           -237.,  327.,  -72.,  218.,   60.,  -32.,  -53., -131., 1930
     4           -118.,  -74.,   58.,   60.,   53.,    4.,   -9.,  102., 1930
     5           -242.,   19.,  -32.,  -16.,   32.,    8., -104.,  -46., 1930
     6             74.,  -54.,  -51.,    4.,  -15.,   25.,  -14.,  -34., 1930
     7              6.,  -12.,   29.,   18.,  -18.,    6.,  -20.,   11., 1930
     8              7.,    8.,   -3.,  -15.,   -9.,    5.,    2.,  -14., 1930
     9              5.,    5.,   -6.,   18.,    8.,   -5.,    8.,  -19., 1930
     a              8.,   10.,  -20.,    1.,   14.,  -12.,    5.,   12., 1930
     b             -3.,    1.,   -2.,   -2.,    9.,    3.,   10.,    0., 1930
     c             -2.,   -2.,    2.,   -3.,   -4.,    2.,    2.,    1., 1930
     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1930
     e              0.,   -2.,    1.,    4.,    3.,    0.,    0.,   -6./ 1930
      data g7/ -30715.,-2306., 5812.,-1018., 2984.,-1520., 1550.,  586., 1935
     1           1206.,-1740., -494., 1215.,  146.,  918.,  101.,  903., 1935
     2            744.,  188.,  565., -226., -415.,  -90.,  249., -114., 1935
     3           -241.,  329.,  -51.,  211.,   64.,  -33.,  -64., -136., 1935
     4           -115.,  -76.,   64.,   59.,   53.,    4.,   -8.,  104., 1935
     5           -246.,   25.,  -25.,  -15.,   25.,    4., -106.,  -40., 1935
     6             74.,  -53.,  -52.,    4.,  -17.,   23.,  -14.,  -33., 1935
     7              7.,  -11.,   29.,   18.,  -19.,    6.,  -19.,   11., 1935
     8              7.,    8.,   -3.,  -15.,   -9.,    5.,    1.,  -15., 1935
     9              6.,    5.,   -6.,   18.,    8.,   -5.,    7.,  -19., 1935
     a              8.,   10.,  -20.,    1.,   15.,  -12.,    5.,   11., 1935
     b             -3.,    1.,   -3.,   -2.,    9.,    3.,   11.,    0., 1935
     c             -2.,   -2.,    2.,   -3.,   -4.,    2.,    2.,    1., 1935
     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1935
     e              0.,   -1.,    2.,    4.,    3.,    0.,    0.,   -6./ 1935
      data g8/ -30654.,-2292., 5821.,-1106., 2981.,-1614., 1566.,  528., 1940
     1           1240.,-1790., -499., 1232.,  163.,  916.,   43.,  914., 1940
     2            762.,  169.,  550., -252., -405.,  -72.,  265., -141., 1940
     3           -241.,  334.,  -33.,  208.,   71.,  -33.,  -75., -141., 1940
     4           -113.,  -76.,   69.,   57.,   54.,    4.,   -7.,  105., 1940
     5           -249.,   33.,  -18.,  -15.,   18.,    0., -107.,  -33., 1940
     6             74.,  -53.,  -52.,    4.,  -18.,   20.,  -14.,  -31., 1940
     7              7.,   -9.,   29.,   17.,  -20.,    5.,  -19.,   11., 1940
     8              7.,    8.,   -3.,  -14.,  -10.,    5.,    1.,  -15., 1940
     9              6.,    5.,   -5.,   19.,    9.,   -5.,    7.,  -19., 1940
     a              8.,   10.,  -21.,    1.,   15.,  -12.,    5.,   11., 1940
     b             -3.,    1.,   -3.,   -2.,    9.,    3.,   11.,    1., 1940
     c             -2.,   -2.,    2.,   -3.,   -4.,    2.,    2.,    1., 1940
     d             -5.,    2.,   -2.,    6.,    6.,   -4.,    4.,    0., 1940
     e              0.,   -1.,    2.,    4.,    3.,    0.,    0.,   -6./ 1940
      data g9/ -30594.,-2285., 5810.,-1244., 2990.,-1702., 1578.,  477., 1945
     1           1282.,-1834., -499., 1255.,  186.,  913.,  -11.,  944., 1945
     2            776.,  144.,  544., -276., -421.,  -55.,  304., -178., 1945
     3           -253.,  346.,  -12.,  194.,   95.,  -20.,  -67., -142., 1945
     4           -119.,  -82.,   82.,   59.,   57.,    6.,    6.,  100., 1945
     5           -246.,   16.,  -25.,   -9.,   21.,  -16., -104.,  -39., 1945
     6             70.,  -40.,  -45.,    0.,  -18.,    0.,    2.,  -29., 1945
     7              6.,  -10.,   28.,   15.,  -17.,   29.,  -22.,   13., 1945
     8              7.,   12.,   -8.,  -21.,   -5.,  -12.,    9.,   -7., 1945
     9              7.,    2.,  -10.,   18.,    7.,    3.,    2.,  -11., 1945
     a              5.,  -21.,  -27.,    1.,   17.,  -11.,   29.,    3., 1945
     b             -9.,   16.,    4.,   -3.,    9.,   -4.,    6.,   -3., 1945
     c              1.,   -4.,    8.,   -3.,   11.,    5.,    1.,    1., 1945
     d              2.,  -20.,   -5.,   -1.,   -1.,   -6.,    8.,    6., 1945
     e             -1.,   -4.,   -3.,   -2.,    5.,    0.,   -2.,   -2./ 1945
      data ga/ -30554.,-2250., 5815.,-1341., 2998.,-1810., 1576.,  381., 1950
     1           1297.,-1889., -476., 1274.,  206.,  896.,  -46.,  954., 1950
     2            792.,  136.,  528., -278., -408.,  -37.,  303., -210., 1950
     3           -240.,  349.,    3.,  211.,  103.,  -20.,  -87., -147., 1950
     4           -122.,  -76.,   80.,   54.,   57.,   -1.,    4.,   99., 1950
     5           -247.,   33.,  -16.,  -12.,   12.,  -12., -105.,  -30., 1950
     6             65.,  -55.,  -35.,    2.,  -17.,    1.,    0.,  -40., 1950
     7             10.,   -7.,   36.,    5.,  -18.,   19.,  -16.,   22., 1950
     8             15.,    5.,   -4.,  -22.,   -1.,    0.,   11.,  -21., 1950
     9             15.,   -8.,  -13.,   17.,    5.,   -4.,   -1.,  -17., 1950
     a              3.,   -7.,  -24.,   -1.,   19.,  -25.,   12.,   10., 1950
     b              2.,    5.,    2.,   -5.,    8.,   -2.,    8.,    3., 1950
     c            -11.,    8.,   -7.,   -8.,    4.,   13.,   -1.,   -2., 1950
     d             13.,  -10.,   -4.,    2.,    4.,   -3.,   12.,    6., 1950
     e              3.,   -3.,    2.,    6.,   10.,   11.,    3.,    8./ 1950
      data gb/ -30500.,-2215., 5820.,-1440., 3003.,-1898., 1581.,  291., 1955
     1           1302.,-1944., -462., 1288.,  216.,  882.,  -83.,  958., 1955
     2            796.,  133.,  510., -274., -397.,  -23.,  290., -230., 1955
     3           -229.,  360.,   15.,  230.,  110.,  -23.,  -98., -152., 1955
     4           -121.,  -69.,   78.,   47.,   57.,   -9.,    3.,   96., 1955
     5           -247.,   48.,   -8.,  -16.,    7.,  -12., -107.,  -24., 1955
     6             65.,  -56.,  -50.,    2.,  -24.,   10.,   -4.,  -32., 1955
     7              8.,  -11.,   28.,    9.,  -20.,   18.,  -18.,   11., 1955
     8              9.,   10.,   -6.,  -15.,  -14.,    5.,    6.,  -23., 1955
     9             10.,    3.,   -7.,   23.,    6.,   -4.,    9.,  -13., 1955
     a              4.,    9.,  -11.,   -4.,   12.,   -5.,    7.,    2., 1955
     b              6.,    4.,   -2.,    1.,   10.,    2.,    7.,    2., 1955
     c             -6.,    5.,    5.,   -3.,   -5.,   -4.,   -1.,    0., 1955
     d              2.,   -8.,   -3.,   -2.,    7.,   -4.,    4.,    1., 1955
     e             -2.,   -3.,    6.,    7.,   -2.,   -1.,    0.,   -3./ 1955
      data gc/ -30421.,-2169., 5791.,-1555., 3002.,-1967., 1590.,  206., 1960
     1           1302.,-1992., -414., 1289.,  224.,  878., -130.,  957., 1960
     2            800.,  135.,  504., -278., -394.,    3.,  269., -255., 1960
     3           -222.,  362.,   16.,  242.,  125.,  -26., -117., -156., 1960
     4           -114.,  -63.,   81.,   46.,   58.,  -10.,    1.,   99., 1960
     5           -237.,   60.,   -1.,  -20.,   -2.,  -11., -113.,  -17., 1960
     6             67.,  -56.,  -55.,    5.,  -28.,   15.,   -6.,  -32., 1960
     7              7.,   -7.,   23.,   17.,  -18.,    8.,  -17.,   15., 1960
     8              6.,   11.,   -4.,  -14.,  -11.,    7.,    2.,  -18., 1960
     9             10.,    4.,   -5.,   23.,   10.,    1.,    8.,  -20., 1960
     a              4.,    6.,  -18.,    0.,   12.,   -9.,    2.,    1., 1960
     b              0.,    4.,   -3.,   -1.,    9.,   -2.,    8.,    3., 1960
     c              0.,   -1.,    5.,    1.,   -3.,    4.,    4.,    1., 1960
     d              0.,    0.,   -1.,    2.,    4.,   -5.,    6.,    1., 1960
     e              1.,   -1.,   -1.,    6.,    2.,    0.,    0.,   -7./ 1960
      data gd/ -30334.,-2119., 5776.,-1662., 2997.,-2016., 1594.,  114., 1965
     1           1297.,-2038., -404., 1292.,  240.,  856., -165.,  957., 1965
     2            804.,  148.,  479., -269., -390.,   13.,  252., -269., 1965
     3           -219.,  358.,   19.,  254.,  128.,  -31., -126., -157., 1965
     4            -97.,  -62.,   81.,   45.,   61.,  -11.,    8.,  100., 1965
     5           -228.,   68.,    4.,  -32.,    1.,   -8., -111.,   -7., 1965
     6             75.,  -57.,  -61.,    4.,  -27.,   13.,   -2.,  -26., 1965
     7              6.,   -6.,   26.,   13.,  -23.,    1.,  -12.,   13., 1965
     8              5.,    7.,   -4.,  -12.,  -14.,    9.,    0.,  -16., 1965
     9              8.,    4.,   -1.,   24.,   11.,   -3.,    4.,  -17., 1965
     a              8.,   10.,  -22.,    2.,   15.,  -13.,    7.,   10., 1965
     b             -4.,   -1.,   -5.,   -1.,   10.,    5.,   10.,    1., 1965
     c             -4.,   -2.,    1.,   -2.,   -3.,    2.,    2.,    1., 1965
     d             -5.,    2.,   -2.,    6.,    4.,   -4.,    4.,    0., 1965
     e              0.,   -2.,    2.,    3.,    2.,    0.,    0.,   -6./ 1965
      data ge/ -30220.,-2068., 5737.,-1781., 3000.,-2047., 1611.,   25., 1970
     1           1287.,-2091., -366., 1278.,  251.,  838., -196.,  952., 1970
     2            800.,  167.,  461., -266., -395.,   26.,  234., -279., 1970
     3           -216.,  359.,   26.,  262.,  139.,  -42., -139., -160., 1970
     4            -91.,  -56.,   83.,   43.,   64.,  -12.,   15.,  100., 1970
     5           -212.,   72.,    2.,  -37.,    3.,   -6., -112.,    1., 1970
     6             72.,  -57.,  -70.,    1.,  -27.,   14.,   -4.,  -22., 1970
     7              8.,   -2.,   23.,   13.,  -23.,   -2.,  -11.,   14., 1970
     8              6.,    7.,   -2.,  -15.,  -13.,    6.,   -3.,  -17., 1970
     9              5.,    6.,    0.,   21.,   11.,   -6.,    3.,  -16., 1970
     a              8.,   10.,  -21.,    2.,   16.,  -12.,    6.,   10., 1970
     b             -4.,   -1.,   -5.,    0.,   10.,    3.,   11.,    1., 1970
     c             -2.,   -1.,    1.,   -3.,   -3.,    1.,    2.,    1., 1970
     d             -5.,    3.,   -1.,    4.,    6.,   -4.,    4.,    0., 1970
     e              1.,   -1.,    0.,    3.,    3.,    1.,   -1.,   -4./ 1970
      data gf/ -30100.,-2013., 5675.,-1902., 3010.,-2067., 1632.,  -68., 1975
     1           1276.,-2144., -333., 1260.,  262.,  830., -223.,  946., 1975
     2            791.,  191.,  438., -265., -405.,   39.,  216., -288., 1975
     3           -218.,  356.,   31.,  264.,  148.,  -59., -152., -159., 1975
     4            -83.,  -49.,   88.,   45.,   66.,  -13.,   28.,   99., 1975
     5           -198.,   75.,    1.,  -41.,    6.,   -4., -111.,   11., 1975
     6             71.,  -56.,  -77.,    1.,  -26.,   16.,   -5.,  -14., 1975
     7             10.,    0.,   22.,   12.,  -23.,   -5.,  -12.,   14., 1975
     8              6.,    6.,   -1.,  -16.,  -12.,    4.,   -8.,  -19., 1975
     9              4.,    6.,    0.,   18.,   10.,  -10.,    1.,  -17., 1975
     a              7.,   10.,  -21.,    2.,   16.,  -12.,    7.,   10., 1975
     b             -4.,   -1.,   -5.,   -1.,   10.,    4.,   11.,    1., 1975
     c             -3.,   -2.,    1.,   -3.,   -3.,    1.,    2.,    1., 1975
     d             -5.,    3.,   -2.,    4.,    5.,   -4.,    4.,   -1., 1975
     e              1.,   -1.,    0.,    3.,    3.,    1.,   -1.,   -5./ 1975
      data gg/ -29992.,-1956., 5604.,-1997., 3027.,-2129., 1663., -200., 1980
     1           1281.,-2180., -336., 1251.,  271.,  833., -252.,  938., 1980
     2            782.,  212.,  398., -257., -419.,   53.,  199., -297., 1980
     3           -218.,  357.,   46.,  261.,  150.,  -74., -151., -162., 1980
     4            -78.,  -48.,   92.,   48.,   66.,  -15.,   42.,   93., 1980
     5           -192.,   71.,    4.,  -43.,   14.,   -2., -108.,   17., 1980
     6             72.,  -59.,  -82.,    2.,  -27.,   21.,   -5.,  -12., 1980
     7             16.,    1.,   18.,   11.,  -23.,   -2.,  -10.,   18., 1980
     8              6.,    7.,    0.,  -18.,  -11.,    4.,   -7.,  -22., 1980
     9              4.,    9.,    3.,   16.,    6.,  -13.,   -1.,  -15., 1980
     a              5.,   10.,  -21.,    1.,   16.,  -12.,    9.,    9., 1980
     b             -5.,   -3.,   -6.,   -1.,    9.,    7.,   10.,    2., 1980
     c             -6.,   -5.,    2.,   -4.,   -4.,    1.,    2.,    0., 1980
     d             -5.,    3.,   -2.,    6.,    5.,   -4.,    3.,    0., 1980
     e              1.,   -1.,    2.,    4.,    3.,    0.,    0.,   -6./ 1980
      data gi/ -29873.,-1905., 5500.,-2072., 3044.,-2197., 1687., -306., 1985
     1           1296.,-2208., -310., 1247.,  284.,  829., -297.,  936., 1985
     2            780.,  232.,  361., -249., -424.,   69.,  170., -297., 1985
     3           -214.,  355.,   47.,  253.,  150.,  -93., -154., -164., 1985
     4            -75.,  -46.,   95.,   53.,   65.,  -16.,   51.,   88., 1985
     5           -185.,   69.,    4.,  -48.,   16.,   -1., -102.,   21., 1985
     6             74.,  -62.,  -83.,    3.,  -27.,   24.,   -2.,   -6., 1985
     7             20.,    4.,   17.,   10.,  -23.,    0.,   -7.,   21., 1985
     8              6.,    8.,    0.,  -19.,  -11.,    5.,   -9.,  -23., 1985
     9              4.,   11.,    4.,   14.,    4.,  -15.,   -4.,  -11., 1985
     a              5.,   10.,  -21.,    1.,   15.,  -12.,    9.,    9., 1985
     b             -6.,   -3.,   -6.,   -1.,    9.,    7.,    9.,    1., 1985
     c             -7.,   -5.,    2.,   -4.,   -4.,    1.,    3.,    0., 1985
     d             -5.,    3.,   -2.,    6.,    5.,   -4.,    3.,    0., 1985
     e              1.,   -1.,    2.,    4.,    3.,    0.,    0.,   -6./ 1985
      data gj/ -29775.,-1848., 5406.,-2131., 3059.,-2279., 1686., -373., 1990
     1           1314.,-2239., -284., 1248.,  293.,  802., -352.,  939., 1990
     2            780.,  247.,  325., -240., -423.,   84.,  141., -299., 1990
     3           -214.,  353.,   46.,  245.,  154., -109., -153., -165., 1990
     4            -69.,  -36.,   97.,   61.,   65.,  -16.,   59.,   82., 1990
     5           -178.,   69.,    3.,  -52.,   18.,    1.,  -96.,   24., 1990
     6             77.,  -64.,  -80.,    2.,  -26.,   26.,    0.,   -1., 1990
     7             21.,    5.,   17.,    9.,  -23.,    0.,   -4.,   23., 1990
     8              5.,   10.,   -1.,  -19.,  -10.,    6.,  -12.,  -22., 1990
     9              3.,   12.,    4.,   12.,    2.,  -16.,   -6.,  -10., 1990
     a              4.,    9.,  -20.,    1.,   15.,  -12.,   11.,    9., 1990
     b             -7.,   -4.,   -7.,   -2.,    9.,    7.,    8.,    1., 1990
     c             -7.,   -6.,    2.,   -3.,   -4.,    2.,    2.,    1., 1990
     d             -5.,    3.,   -2.,    6.,    4.,   -4.,    3.,    0., 1990
     e              1.,   -2.,    3.,    3.,    3.,   -1.,    0.,   -6./ 1990
      data gk/ -29692.,-1784., 5306.,-2200., 3070.,-2366., 1681., -413., 1995
     1           1335.,-2267., -262., 1249.,  302.,  759., -427.,  940., 1995
     2            780.,  262.,  290., -236., -418.,   97.,  122., -306., 1995
     3           -214.,  352.,   46.,  235.,  165., -118., -143., -166., 1995
     4            -55.,  -17.,  107.,   68.,   67.,  -17.,   68.,   72., 1995
     5           -170.,   67.,   -1.,  -58.,   19.,    1.,  -93.,   36., 1995
     6             77.,  -72.,  -69.,    1.,  -25.,   28.,    4.,    5., 1995
     7             24.,    4.,   17.,    8.,  -24.,   -2.,   -6.,   25., 1995
     8              6.,   11.,   -6.,  -21.,   -9.,    8.,  -14.,  -23., 1995
     9              9.,   15.,    6.,   11.,   -5.,  -16.,   -7.,   -4., 1995
     a              4.,    9.,  -20.,    3.,   15.,  -10.,   12.,    8., 1995
     b             -6.,   -8.,   -8.,   -1.,    8.,   10.,    5.,   -2., 1995
     c             -8.,   -8.,    3.,   -3.,   -6.,    1.,    2.,    0., 1995
     d             -4.,    4.,   -1.,    5.,    4.,   -5.,    2.,   -1., 1995
     e              2.,   -2.,    5.,    1.,    1.,   -2.,    0.,   -7., 1995
     f           75*0./                                                  1995
      data gl/ -29619.4,-1728.2, 5186.1,-2267.7, 3068.4,-2481.6, 1670.9, 2000
     1           -458.0, 1339.6,-2288.0, -227.6, 1252.1,  293.4,  714.5, 2000
     2           -491.1,  932.3,  786.8,  272.6,  250.0, -231.9, -403.0, 2000
     3            119.8,  111.3, -303.8, -218.8,  351.4,   43.8,  222.3, 2000
     4            171.9, -130.4, -133.1, -168.6,  -39.3,  -12.9,  106.3, 2000
     5             72.3,   68.2,  -17.4,   74.2,   63.7, -160.9,   65.1, 2000
     6             -5.9,  -61.2,   16.9,    0.7,  -90.4,   43.8,   79.0, 2000
     7            -74.0,  -64.6,    0.0,  -24.2,   33.3,    6.2,    9.1, 2000
     8             24.0,    6.9,   14.8,    7.3,  -25.4,   -1.2,   -5.8, 2000
     9             24.4,    6.6,   11.9,   -9.2,  -21.5,   -7.9,    8.5, 2000
     a            -16.6,  -21.5,    9.1,   15.5,    7.0,    8.9,   -7.9, 2000
     b            -14.9,   -7.0,   -2.1,    5.0,    9.4,  -19.7,    3.0, 2000
     c             13.4,   -8.4,   12.5,    6.3,   -6.2,   -8.9,   -8.4, 2000
     d             -1.5,    8.4,    9.3,    3.8,   -4.3,   -8.2,   -8.2, 2000
     e              4.8,   -2.6,   -6.0,    1.7,    1.7,    0.0,   -3.1, 2000
     f              4.0,   -0.5,    4.9,    3.7,   -5.9,    1.0,   -1.2, 2000
     g              2.0,   -2.9,    4.2,    0.2,    0.3,   -2.2,   -1.1, 2000
     h             -7.4,    2.7,   -1.7,    0.1,   -1.9,    1.3,    1.5, 2000
     i             -0.9,   -0.1,   -2.6,    0.1,    0.9,   -0.7,   -0.7, 2000
     j              0.7,   -2.8,    1.7,   -0.9,    0.1,   -1.2,    1.2, 2000
     k             -1.9,    4.0,   -0.9,   -2.2,   -0.3,   -0.4,    0.2, 2000
     l              0.3,    0.9,    2.5,   -0.2,   -2.6,    0.9,    0.7, 2000
     m             -0.5,    0.3,    0.3,    0.0,   -0.3,    0.0,   -0.4, 2000
     n              0.3,   -0.1,   -0.9,   -0.2,   -0.4,   -0.4,    0.8, 2000
     o             -0.2,   -0.9,   -0.9,    0.3,    0.2,    0.1,    1.8, 2000
     p             -0.4,   -0.4,    1.3,   -1.0,   -0.4,   -0.1,    0.7, 2000
     q              0.7,   -0.4,    0.3,    0.3,    0.6,   -0.1,    0.3, 2000
     r              0.4,   -0.2,    0.0,   -0.5,    0.1,   -0.9/         2000
      data gm/ -29556.8,-1671.8, 5080.0,-2340.5, 3047.0,-2594.9, 1656.9, 2005
     1           -516.7, 1335.7,-2305.3, -200.4, 1246.8,  269.3,  674.4, 2005
     2           -524.5,  919.8,  798.2,  281.4,  211.5, -225.8, -379.5, 2005
     3            145.7,  100.2, -304.7, -227.6,  354.4,   42.7,  208.8, 2005
     4            179.8, -136.6, -123.0, -168.3,  -19.5,  -14.1,  103.6, 2005
     5             72.9,   69.6,  -20.2,   76.6,   54.7, -151.1,   63.7, 2005
     6            -15.0,  -63.4,   14.7,    0.0,  -86.4,   50.3,   79.8, 2005
     7            -74.4,  -61.4,   -1.4,  -22.5,   38.6,    6.9,   12.3, 2005
     8             25.4,    9.4,   10.9,    5.5,  -26.4,    2.0,   -4.8, 2005
     9             24.8,    7.7,   11.2,  -11.4,  -21.0,   -6.8,    9.7, 2005
     a            -18.0,  -19.8,   10.0,   16.1,    9.4,    7.7,  -11.4, 2005
     b            -12.8,   -5.0,   -0.1,    5.6,    9.8,  -20.1,    3.6, 2005
     c             12.9,   -7.0,   12.7,    5.0,   -6.7,  -10.8,   -8.1, 2005
     d             -1.3,    8.1,    8.7,    2.9,   -6.7,   -7.9,   -9.2, 2005
     e              5.9,   -2.2,   -6.3,    2.4,    1.6,    0.2,   -2.5, 2005
     f              4.4,   -0.1,    4.7,    3.0,   -6.5,    0.3,   -1.0, 2005
     g              2.1,   -3.4,    3.9,   -0.9,   -0.1,   -2.3,   -2.2, 2005
     h             -8.0,    2.9,   -1.6,    0.3,   -1.7,    1.4,    1.5, 2005
     i             -0.7,   -0.2,   -2.4,    0.2,    0.9,   -0.7,   -0.6, 2005
     j              0.5,   -2.7,    1.8,   -1.0,    0.1,   -1.5,    1.0, 2005
     k             -2.0,    4.1,   -1.4,   -2.2,   -0.3,   -0.5,    0.3, 2005
     l              0.3,    0.9,    2.3,   -0.4,   -2.7,    1.0,    0.6, 2005
     m             -0.4,    0.4,    0.5,    0.0,   -0.3,    0.0,   -0.4, 2005
     n              0.3,    0.0,   -0.8,   -0.4,   -0.4,    0.0,    1.0, 2005
     o             -0.2,   -0.9,   -0.7,    0.3,    0.3,    0.3,    1.7, 2005
     p             -0.4,   -0.5,    1.2,   -1.0,   -0.4,    0.0,    0.7, 2005
     q              0.7,   -0.3,    0.2,    0.4,    0.6,   -0.1,    0.4, 2005
     r              0.4,   -0.2,   -0.1,   -0.5,   -0.3,   -1.0/         2005
      data gp/     8.8,  10.8, -21.3, -15.0,  -6.9, -23.3,  -1.0, -14.0, 2007
     1            -0.3,  -3.1,   5.4,  -0.9,  -6.5,  -6.8,  -2.0,  -2.5, 2007
     2             2.8,   2.0,  -7.1,   1.8,   5.9,   5.6,  -3.2,   0.0, 2007
     3            -2.6,   0.4,   0.1,  -3.0,   1.8,  -1.2,   2.0,   0.2, 2007
     4             4.5,  -0.6,  -1.0,  -0.8,   0.2,  -0.4,  -0.2,  -1.9, 2007
     5             2.1,  -0.4,  -2.1,  -0.4,  -0.4,  -0.2,   1.3,   0.9, 2007
     6            -0.4,   0.0,   0.8,  -0.2,   0.4,   1.1,   0.1,   0.6, 2007
     7             0.2,   0.4,  -0.9,  -0.5,  -0.3,   0.9,   0.3,  -0.2, 2007
     8             0.2,  -0.2,  -0.2,   0.2,   0.2,   0.2,  -0.2,   0.4, 2007
     9             0.2,   0.2,   0.5,  -0.3,  -0.7,   0.5,   0.5,   0.4, 2007
     a         115*0.0/                                                  2007
c
c     set initial values
c


C        print *, date, radius, clatit, slatit, clongi, slongi


      x     = 0.0
      y     = 0.0
      z     = 0.0
C	convert from the input parameters to the IGRF parameters
C	this wants the radius in km
      alt = radius * 0.001 



      if (date.lt.1900.0.or.date.gt.2015.0) go to 11
c$$$      if (date.gt.2010.0) write (6,960) date
c$$$  960 format (/' This version of the IGRF is intended for use up',
c$$$     1        ' to 2010.0.'/' values for',f9.3,' will be computed',
c$$$     2        ' but may be of reduced accuracy'/)
      if (date.ge.2005.0) go to 1
      t     = 0.2*(date - 1900.0)                                             
      ll    = t
      one   = ll
      t     = t - one
      if (date.lt.1995.0) then
       nmx   = 10
       nc    = nmx*(nmx+2)
       ll    = nc*ll
       kmx   = (nmx+1)*(nmx+2)/2
      else
       nmx   = 13
       nc    = nmx*(nmx+2)
       ll    = 0.2*(date - 1995.0)
       ll    = 120*19 + nc*ll
       kmx   = (nmx+1)*(nmx+2)/2
      endif
      tc    = 1.0 - t
c$$$      if (isv.eq.1) then
c$$$       tc = -0.2
c$$$       t = 0.2
c$$$      end if
      go to 2
c
    1 t     = date - 2005.0
      tc    = 1.0
c$$$      if (isv.eq.1) then
c$$$       t = 1.0
c$$$       tc = 0.0
c$$$      end if
      ll    = 2670
      nmx   = 13
      nc    = nmx*(nmx+2)
      kmx   = (nmx+1)*(nmx+2)/2
    2 r     = alt
C      one   = colat*0.017453292
      ct    = slatit !cos(one)
      st    = clatit !sin(one)
C      one   = elong*0.017453292
      cl(1) = clongi !cos(one)
      sl(1) = slongi !sin(one)
c$$$      cd    = 1.0
c$$$      sd    = 0.0
      l     = 1
      m     = 1
      n     = 0
c$$$      if (itype.eq.2) go to 3
c$$$c
c$$$c     conversion from geodetic to geocentric coordinates 
c$$$c     (using the WGS84 spheroid)
c$$$c
c$$$      a2    = 40680631.6
c$$$      b2    = 40408296.0
c$$$      one   = a2*st*st
c$$$      two   = b2*ct*ct
c$$$      three = one + two
c$$$      rho   = sqrt(three)
c$$$      r     = sqrt(alt*(alt + 2.0*rho) + (a2*one + b2*two)/three)
c$$$      cd    = (alt + rho)/r
c$$$      sd    = (a2 - b2)/rho*ct*st/r
c$$$      one   = ct
c$$$      ct    = ct*cd -  st*sd
c$$$      st    = st*cd + one*sd
c
    3 ratio = 6371.2/r
      rr    = ratio*ratio
c
c     computation of Schmidt quasi-normal coefficients p and x(=q)
c
      p(1)  = 1.0
      p(3)  = st
      q(1)  = 0.0
      q(3)  =  ct
      do 10 k=2,kmx                                                       
      if (n.ge.m) go to 4
      m     = 0
      n     = n + 1
      rr    = rr*ratio
      fn    = n
      gn    = n - 1
    4 fm    = m
      if (m.ne.n) go to 5
      if (k.eq.3) go to 6
      one   = sqrt(1.0 - 0.5/fm)
      j     = k - n - 1
      p(k)  = one*st*p(j)
      q(k)  = one*(st*q(j) + ct*p(j))
      cl(m) = cl(m-1)*cl(1) - sl(m-1)*sl(1)
      sl(m) = sl(m-1)*cl(1) + cl(m-1)*sl(1)
      go to 6                                                           
    5 gmm    = m*m
      one   = sqrt(fn*fn - gmm)
      two   = sqrt(gn*gn - gmm)/one
      three = (fn + gn)/one
      i     = k - n
      j     = i - n + 1
      p(k)  = three*ct*p(i) - two*p(j)
      q(k)  = three*(ct*q(i) - st*p(i)) - two*q(j)
c
c     synthesis of x, y and z in geocentric coordinates
c
    6 lm    = ll + l
      one   = (tc*gh(lm) + t*gh(lm+nc))*rr                                     
      if (m.eq.0) go to 9                                                      
      two   = (tc*gh(lm+1) + t*gh(lm+nc+1))*rr
      three = one*cl(m) + two*sl(m)
      x     = x + three*q(k)
      z     = z - (fn + 1.0)*three*p(k)
      if (st.eq.0.0) go to 7
      y     = y + (one*sl(m) - two*cl(m))*fm*p(k)/st
      go to 8
    7 y     = y + (one*sl(m) - two*cl(m))*q(k)*ct
    8 l     = l + 2
      go to 10
    9 x     = x + one*q(k)
      z     = z - (fn + 1.0)*one*p(k)
      l     = l + 1
   10 m     = m + 1
c
c     conversion to coordinate system specified by itype
c
C	JMA because we are geocentric only, there is no need to convert
C	anything.  (cd==1, sd==0).  Also, we don't return f, so do nothing.
c$$$      one   = x
c$$$      x     = x*cd +   z*sd
c$$$      z     = z*cd - one*sd
c$$$      f     = sqrt(x*x + y*y + z*z)
c
C	But do convert to Tesla
      x = x * 1.0D-9
      y = y * 1.0D-9
      z = z * 1.0D-9
c$$$      f = f * 1.0D-9
C      print *, x, y, z
      return
c
c     error return if date out of bounds
c
   11 CONTINUE
c$$$      f     = 1.0d8
      write (LUSTDERR,961) date
  961 format (/' This subroutine will not work with a date of',
     1        f9.3,'.  Date must be in the range 1900.0.ge.date',
     2        '.le.2015.0.  On return f = 1.0d8., x = y = z = 0.')
      return
      end
