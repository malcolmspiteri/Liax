%ifndef _FAT12_INC
%define _FAT12_INC

%define FAT12_FILE_SYSTEM 'FAT12', 0x20, 0x20, 0x20

struc fat_oem_block

      oem:			resb	8
      bytes_per_sector:		resw	1
      sectors_per_cluster:	resb 	1
      reserved_sectors:		resw	1
      no_fats:			resb	1
      no_root_entries:		resw	1
      no_sectors:		resw	1
      media:			resb	1
      sectors_per_fat:		resw	1
      sectors_per_track:	resw	1
      heads_per_cylinder:	resw	1
      no_hidden_sectors:	resd	1
      no_large_sectors:		resd	1
      drive_number:		resb	1
      unused:			resb	1
      ext_boot_sig:		resb	1
      serial_number:		resd	1
      valume_label:		resb	11
      file_system:		resb 	8

endstruc

%endif