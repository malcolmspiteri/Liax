%ifndef _BIOSDIO_INC
%define _BIOSDIO_INC

%define READ_SECTORS_RETRIES 5
%define READ_SECTORS_TRACK 5

struc dchs
      drive:		resb	1
      cylinder:		resb	1
      head:		resb	1
      sector:		resb 	1
      datasector:	resw    1
      cluster:		resw    1
endstruc
	
%endif