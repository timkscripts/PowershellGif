#Setup File path and bytes
$FilePath =  "C:\Users\Bablon\Desktop\candyk.gif"

[Byte[]]  $fileBytes = [System.IO.File]::ReadAllBytes( $(resolve-path $FilePath ) );
$pb = 0; #pointer into filebytes

#program tracker
$progLocation = 0;
$GCTByteLength = -99;
$CEByteLength = -99;
$end = $false; #true means end of file

# Header Variables
[Byte[]] $head_sig =  New-Object Byte[] 0 #"";
[Byte[]] $head_ver =  New-Object Byte[] 0 #"";

#Logical Screen Descriptors
[Byte[]] $LSD_width =  New-Object Byte[] 0 #"";
[Byte[]] $LSD_height =  New-Object Byte[] 0 #"";
[Byte[]] $LSD_PackedField = New-Object Byte[] 0 #"";
[Byte[]] $LSD_BackgroundColorIndex = New-Object Byte[] 0 #"";
[Byte[]] $LSD_PixelAspectRatio = New-Object Byte[] 0 #"";

#Packed Field values for LSD
$LSD_PF_GCTF = ""; #global color table flag
$LSD_PF_CR = ""; #color resolution
$LSD_PF_SF = ""; #sort flag
$LSD_PF_SGCT = ""; #size of global color table

#Global Color Table
$GCT_size = 6;
#$GCT_bytes = "";
$GCT_bytes = New-Object Byte[] 0;
#Graphics Control Extension
[Byte[]] $GCE_Intro =  New-Object Byte[] 0 #21;
[Byte[]] $GCE_GCL =  New-Object Byte[] 0 #graphic control label
[Byte[]] $GCE_ByteSize =  New-Object Byte[] 0 
[Byte[]] $GCE_PackedField =  New-Object Byte[] 0 
[Byte[]] $GCE_DelayTime =  New-Object Byte[] 0 
[Byte[]] $GCE_TransCI =  New-Object Byte[] 0 #transparent color index
[Byte[]] $GCE_BlockTerminator = New-Object Byte[] 0 

#Packed Field Values for GCE


#Application Extension
[Byte[]] $AE_GEC = New-Object Byte[] 0 #21, graphical extension code
[Byte[]] $AE_AEL = New-Object Byte[] 0 #FF, application extension Label
[Byte[]] $AE_LAP = New-Object Byte[] 0 #0B, length of application block
[Byte[]] $AE_Netscape = New-Object Byte[] 0 #8 bytes that spell "NETSCAPE"
[Byte[]] $AE_Ver = New-Object Byte[] 0 #"2.0" version bytes
[Byte[]] $AE_LDSB = New-Object Byte[] 0 #length of data sub-block, starts with 0x03 and the next 3 bytes to follow
[Byte[]] $AE_One = New-Object Byte[] 0 #0x01, not sure what this is
[Byte[]] $AE_LoopCounter = New-Object Byte[] 0 #0 to 65,535... 0 is unlimited
[Byte[]] $AE_Terminator = New-Object Byte[] 0 #HEX 0x00, data sub block terminator

#Comment Extension
[Byte[]] $CE_EI = New-Object Byte[] 0 #Extension introducter, 21
[Byte[]] $CE_CL = New-Object Byte[] 0 #comment label, FE
[Byte[]] $CE_ByteCount = New-Object Byte[] 0 #number of bytes in sub block
[Byte[]] $CE_Bytes = New-Object Byte[] 0 #comment bytes ascii
[Byte[]] $CE_Terminator = New-Object Byte[] 0 #terminates CE block, 0x00

#Plain Text Extension
[Byte[]] $PTE_EI = New-Object Byte[] 0 #Extension Introducter, always 21
[Byte[]] $PTE_PTL = New-Object Byte[] 0 #plain text label, always 01
[Byte[]] $PTE_ByteCount = New-Object Byte[] 0 #block size, amount of bytes until actual text begins (how many bytes to skip)
[Byte[]] $PTE_DSB = New-Object Byte[] 0 #Data sub block
[Byte[]] $PTE_Terminator = ""; #terminator, always 0x00

#Extension verifier
$head_bool = $true;
$lsd_bool = $false; #logical screen descriptor
$gct_bool = $false; #global color table
$GCE_bool = $false; #graphics control extension
$AE_bool = $false; #application extension
$CE_bool = $false; #comment extension
$PTE_bool = $false; #plain text extension
$ID_bool = $false; #Image Descriptor
$Data_bool = $false; #image data
$Data_bool2 = $false;
$ext_bool = $false; #used to determine the extension based on first/second bits

#Image Descriptor
[Byte[]] $ID_IS =  New-Object Byte[] 0 #Image Seperator
[Byte[]] $ID_IL =  New-Object Byte[] 0 #Image Left
[Byte[]] $ID_IT =  New-Object Byte[] 0 #Image Top
[Byte[]] $ID_IW =  New-Object Byte[] 0 #image width
[Byte[]] $ID_IH =  New-Object Byte[] 0 #Image Height
[Byte[]] $ID_PackedField = New-Object Byte[] 0 #"";

#Image Data
[Byte[]] $Data_LZW = New-Object Byte[] 0 #minimum code size
$Data_ByteSize = -1; #the number of bytes of data in the sublock (01-ff)
$Data_TempByteSize = 0;
[Byte[]] $Data_Image = New-Object Byte[] 0 #The image data
[Byte[]] $Data_ImageEnd = New-Object Byte[] 0 #The last digit of every data_image is 00,
[Byte[]] $Data_Terminator = New-Object Byte[] 0 #The terminator to the image data is 00


#temp color byte
[Byte[]] $tempcolOr = New-Object Byte[] 0
[Byte] $colorAdjust = 0x10;

#The current Byte
#$mylength = Get-ChildItem  "C:\Users\Bablon\Desktop\crys4.gif" | select-object Length
[byte[]] $currentByte = New-Object Byte[] 0
$setElse = $false;

#master bytes variable
[byte[]] $allBytes = new-object Byte[] 0
$count = new-object Int[] 0
$char = "R"

$allBytes2 = new-object Byte[] 0;

do {
	if ($head_bool){
		write-host "------------------------ SETUP HEADER ------------------------ "
		$head_sig =  $fileBytes[$pb..($pb+2)]
		$pb += 3;
		$head_ver =  $fileBytes[$pb..($pb+2)]
		$pb += 3;

		$head_bool = $false;
		$lsd_bool = $true;

		$allBytes += $head_sig
		$allBytes += $head_ver 

	}
	if ($lsd_bool){
		write-host "------------------------ SETUP LSD ------------------------ "
		$LSD_width = $fileBytes[$pb..($pb+1)]
		$pb += 2;
		$LSD_height = $fileBytes[$pb..($pb+1)]
		$pb += 2;
		$lsd_bool = $false;
		$gct_bool = $true;

		$allBytes += $LSD_width
		$allBytes += $LSD_height

	}
	if ($gct_bool){
		write-host "------------------------ SETUP GCT ------------------------ "
		
	        
	    $LSD_PackedField = $fileBytes[$pb]
	    $ID_PackedField  = $fileBytes[$pb]
	    
	    
	    $LSD_PF_Binary = [System.Convert]::ToString($fileBytes[$pb],2);
	    $pb += 1;
	    if ($LSD_PF_Binary.length -lt 8){
		    do{
		    	$LSD_PF_Binary = "0" + $LSD_PF_Binary;

		    } while ($LSD_PF_Binary.length -lt 8)
		 }

	        $LSD_PF_Binary = $LSD_PF_Binary.toCharArray();
	        $LSD_PF_GCTF = "{0:X2} " -f $LSD_PF_Binary[0];
	        $temp = "";
	        $temp = $LSD_PF_Binary[1];
	        $temp += $LSD_PF_Binary[2];
	        $temp += $LSD_PF_Binary[3];

	        $LSD_PF_CR = "{0:X2} " -f $temp;
	        $LSD_PF_SF = "{0:X2} " -f $LSD_PF_Binary[4];
	        $temp = $LSD_PF_Binary[5];
	        $temp += $LSD_PF_Binary[6];
	        $temp += $LSD_PF_Binary[7];
	        #$temp
	        $LSD_PF_SGCT = "{0:X2} " -f $temp;

	        $GCT_size = [System.Convert]::ToInt16($temp,2);
	        $GCT_size
	        $GCTByteLength = ($pb + 1 + ( 3*([math]::pow(2,($GCT_size+1) ) )) );
	        $GCTByteLength =  [System.Convert]::ToInt16( $GCTByteLength );
	    $LSD_BackgroundColorIndex =  $fileBytes[$pb]
	    $pb += 1;
	    $LSD_PixelAspectRatio  =  $fileBytes[$pb]
	    $pb += 1;
	    $GCT_bytes = $fileBytes[$pb..($GCTByteLength)]
	    $pb = $GCTByteLength + 1;

	    $gct_bool = $false;
	    $ext_bool = $true;
	    write-host "==="
	    $LSD_PackedField 
	    write-host "==="
	    $LSD_BackgroundColorIndex
	    write-host "==="
		$LSD_PixelAspectRatio
		write-host "==="
		$GCT_bytes
		write-host "==="
		$GCTByteLength

	    $allBytes += $LSD_PackedField
	    $allBytes += $LSD_BackgroundColorIndex
	    $allBytes += $LSD_PixelAspectRatio
	    $allBytes += $GCT_bytes

	    
	}

	if ($ext_bool -eq $true){
		if ($fileBytes[$pb] -eq 59){
			$end = $true;
			$AE_bool = $false;
			$ID_bool = $false;
			$CE_bool = $false;
			$GCE_bool = $false;
			#$allBytes += 0

			$allBytes += 59
			write-host 'goodbye'

		}
		if ( ($fileBytes[$pb] -eq 44) -and (! $Data_bool) -and (! $PTE_bool) -and (! $CE_bool) -and (! $AE_bool) -and (! $GCE_bool)){
	      write-host "------------------------ SETUP id------------------------ "
	      $ID_IS = $fileBytes[$pb];
	      $pb += 1;
	      $ID_bool = $true;

	      $allBytes += $ID_IS
	    } else {
	    	$pb += 1;
	    }
	    
	    if ($ID_bool -eq $true){

	    } else {

	      if ($fileBytes[$pb] -eq 255){ #Application Extension
	        write-host "------------------------ SETUP AE ------------------------ "
	        $AE_GEC = $fileBytes[$pb-1]
	        $AE_GEC
	        $AE_AEL = $fileBytes[$pb]
	        $AE_bool = $true;
	        $pb += 1;

	        $allBytes += $AE_GEC
	        $allBytes += $AE_AEL
	      } elseif ($fileBytes[$pb] -eq 254){ #Comment Extension
	        write-host "------------------------ SETUP CE ------------------------ "
	        $CE_EI = $fileBytes[$pb-1]
	        $CE_CL = $fileBytes[$pb]
	        $CE_bool = $true;
	        $pb += 1;

	        $allBytes += $CE_EI
	        $allBytes += $CE_CL
	      } elseif ($fileBytes[$pb] -eq 1){ #Plain Text Extension
	        
	      } elseif ($fileBytes[$pb] -eq 249){ #Graphical Control Extension
	        write-host "------------------------ SETUP GCE ------------------------ "
	        $GCE_Intro = $fileBytes[$pb-1]
	        $GCE_GCL = $fileBytes[$pb];
	        $GCE_bool = $true;
	        $pb += 1;

	        $allBytes += $GCE_Intro
	        $allBytes += $GCE_GCL
	      } else {
	    	
			$end = $true;
	    	
	    	}
	    } 
	    $ext_bool = $false;
	    
	}

	# ---------------------------------------------------------------------  Application Extension
	if ($AE_bool){
		$AE_LAP = $fileBytes[$pb];
		$pb += 1;
		#if 8, end with +7
		$AE_Netscape = $fileBytes[$pb..($pb+7)];
		$pb += 8;
		$AE_Ver = $fileBytes[$pb..($pb+2)];
		$pb += 3;
		$AE_LDSB = $fileBytes[$pb];
		$pb += 1;
	 	$AE_One = $fileBytes[$pb];
	 	$pb += 1;
	 	$AE_LoopCounter = $fileBytes[$pb..($pb+1)];
	 	$pb += 2;
	 	$AE_Terminator =  $fileBytes[$pb];
	 	$pb += 1;
	 	$AE_bool = $false;
	 	$ext_bool = $true;

	 	$allBytes += $AE_LAP
	 	$allBytes += $AE_Netscape
	 	$allBytes += $AE_Ver
	 	$allBytes += $AE_LDSB
	 	$allBytes += $AE_One
	 	$allBytes += $AE_LoopCounter
	 	$allBytes += $AE_Terminator
	}
	# ---------------------------------------------------------------------  Graphical Control Extension
	if ($GCE_bool){
		$GCE_ByteSize = $fileBytes[$pb];
		$pb += 1;
		$GCE_PackedField = $fileBytes[$pb];
		$pb += 1;
		$GCE_DelayTime = $fileBytes[$pb];
		$pb += 1;
		$GCE_DelayTime += $fileBytes[$pb];
		$pb += 1;

		$GCE_TransCI = $fileBytes[$pb];
		$pb += 1;
		$GCE_BlockTerminator = $fileBytes[$pb];
		$pb += 1;

		$GCE_bool = $false;
		$ext_bool = $true;

		$allBytes += $GCE_ByteSize
		$allBytes += $GCE_PackedField
		$allBytes += $GCE_DelayTime
		$allBytes += $GCE_TransCI
		$allBytes += $GCE_BlockTerminator

		
	}
	# ---------------------------------------------------------------------  Comment Extension
	if ($CE_bool){
		$CE_ByteCount = $fileBytes[$pb];
		$CEByteLength = $fileBytes[$pb];
		$pb += 1;
		$CE_Bytes = $fileBytes[$pb..($pb+$CEByteLength-1)];
		$pb = $pb+$CEByteLength;
		$CE_Terminator = $fileBytes[$pb];
		$pb += 1;
		$CE_bool = $false;
		$ext_bool = $true;

		$allBytes += $CE_ByteCount
		#$allBytes += $CEByteLength
		$allBytes += $CE_Bytes
		$allBytes += $CE_Terminator
		

	}
	# ---------------------------------------------------------------------  Image Descriptor
	if ($ID_bool) {
		$ID_IL =  $fileBytes[$pb];
		$pb += 1;
	    $ID_IL +=  $fileBytes[$pb];
		$pb += 1;
	    $ID_IT =  $fileBytes[$pb];
		$pb += 1;
	    $ID_IT +=  $fileBytes[$pb];
		$pb += 1;
	    $ID_IW =  $fileBytes[$pb];
		$pb += 1;
	    $ID_IW +=  $fileBytes[$pb];
		$pb += 1;
	    $ID_IH =  $fileBytes[$pb];
		$pb += 1;
	    $ID_IH +=  $fileBytes[$pb];
		$pb += 1;
		#$ID_PackedField = $fileBytes[$pb];
		$pb += 1;
		$tempcolOr = New-Object Byte[] 0
		

		$Data_LZW = $fileBytes[$pb];
		$pb += 1;
		$Data_bool = $true;
		$ID_bool = $false;

		$allBytes += $ID_IL
		$allBytes += $ID_IT
		$allBytes += $ID_IW
		$allBytes += $ID_IH
		$ID_PackedField

		$tmpPack =$LSD_PF_Binary
		$tmpCount = 0
		write-host "--------------------------------------->>"

		$tmpPack[1] = "0"
		$tmpPack[2] = "0"
		$tmpPack[3] = "0"
		$tmpPack[4] = "0"
		$tmpPack2 = 0
		if ($tmpPack[0] -eq "1"){
			$tmpPack2 += 128
		}
		if ($tmpPack[7] -eq "1"){
			$tmpPack2 += 1
		}

		if ($tmpPack[6] -eq "1"){
			$tmpPack2 += 2
		}

		if ($tmpPack[5] -eq "1"){
			$tmpPack2 += 4
		}
		$tmpPack2

		$allBytes += $tmpPack2; #$ID_PackedField
		#$allBytes += 132
		$tempcolOr = $GCT_bytes | sort-object {get-random}
		$tempCount = 0;
		#$char = "R"
		if ($char -eq "R"){
			$char = "G";
		} elseif ($char -eq "G"){
			$char = "B";
		} elseif ($char -eq "B"){
			$char = "R";
		}


		$tempcolOr | foreach-object {
		$tempCount += 1;
		if ($tempCount -eq 3){
		  if ($char -eq "R"){
		  $allBytes += (Get-Random -Minimum 10 -Maximum 255);
		  $allBytes += 0;
		  $allBytes += 0;
		 
		  
		  } elseif ($char -eq "G"){
		  $allBytes += 0;
		  $allBytes += (Get-Random -Minimum 10 -Maximum 255);
		  $allBytes += 0;
		  
		  } elseif ($char -eq "B"){
		  $allBytes += 0;
		  $allBytes += 0;
		  $allBytes += (Get-Random -Minimum 10 -Maximum 255);
		  
		  }
		  $tempCount = 0;
		  }
		  
		}
		$allBytes += $Data_LZW
	}
	# ---------------------------------------------------------------------  Image Data

	if ($Data_bool){
		write-host "------------------------ SETUP Image Data------------------------ "
		
		$Data_ByteSize = $fileBytes[$pb];
		#$Data_ByteSize
		#$pb += 1;
		#$allBytes += $Data_ByteSize
		if ($Data_ByteSize -ne 0){
			$allBytes2 += $fileBytes[$pb]
			#$Data_Image += $fileBytes[$pb]
			$Data_Image += $fileBytes[($pb+1)..($pb+$Data_ByteSize-0)];
			#$Data_LZW

			#get length
			#$fileByteLength = ($pb+$Data_ByteSize-8) - ($pb+1);
			#$fileByteLength
			$fileLength = $fileBytes[($pb+1)..($pb+$Data_ByteSize-8)].length
			$tempBytes = $fileBytes[($pb+1)..($pb+$Data_ByteSize-8)] | sort-object -unique

			$fileLength -= $tempBytes.length
			#$tempBytes.length
			#$fileBytes[$pb+0]
            #$fileBytes[$pb+1]
            #$fileBytes[$pb+2]
            #$Data_LZW
            #$GCTByteLength
			$allBytes += $fileBytes[$pb]

			#$allBytes += $fileBytes[($pb+1)..($pb+$Data_ByteSize-16)] # | sort-object {get-random};
			$fileBytes[($pb+1)..($pb+$Data_ByteSize+0)] | foreach-object {
			#$_
				#$allBytes += 117 #$_
				#$Data_Image += $_
			}
			#$allBytes += $fileBytes[($pb+$Data_ByteSize-15)..($pb+$Data_ByteSize-0)]
			#$fileBytes[($pb+$Data_ByteSize-7)..($pb+$Data_ByteSize-0)];
			#$allBytes += $fileBytes[($pb+$Data_ByteSize-3)..($pb+$Data_ByteSize-0)];

			$pb = ($pb+$Data_ByteSize)+1

	   #write-host "length--"
			#$allBytes.length
			#$Data_Image.length
		} else {
		write-host "------------------------ end Image Data------------------------ "
			$lwz_colorCodeMin = 0;
			$lwz_colorCodeMax = 0;
			$lwz_clearCode = 0;
			$lwz_EOICode = 0;
			$lwz_BytesToAdd = 0
			[String] $lwz_MasterString = "";
			write-host "--- Start binary stretch"
			if ($Data_LZW -eq 5){
				$lwz_colorCodeMin = 0;
				$lwz_colorCodeMax = 31;
				$lwz_clearCode = 32;
				$lwz_EOICode = 33;
				$lwz_BytesToAdd = [int] (($Data_Image.length * 8) /  ( 5 + 1));
				write-host "bytes to add -> " $lwz_BytesToAdd
				$lwz_MasterString += "00100000"
				for ($e = 0; $e -lt $lwz_BytesToAdd; $e++){
					#random number between 1 and 3
					#$e
					$lwz_randy = 0 #;get-Random -Minimum 0 -Maximum 30;
					write-host "random number -> " $lwz_randy
					#$lwz_randy
					[String] $lwz_rNum = [System.Convert]::ToString($lwz_randy,2);
					if ($lwz_rNum.length -lt 6){
						do {
							$lwz_rNum = "0" + $lwz_rNum;
						} while ($lwz_rNum.length -lt 6)	
					}

					#$lwz_rNum = $lwz_rNum.TrimStart("00");
					write-host "random number bINARY -> " $lwz_rNum
					#write-host "LWZ R NUM" $lwz_rNum
					#$lwz_rNum;
					$lwz_MasterString = $lwz_rNum + $lwz_MasterString
					if ($lwz_MasterString.length -gt 8){
						write-host "master string -> " $lwz_MasterString
						$tmpStringy = "";
						#$lwz_MasterString
						$int1 = [Int] $lwz_MasterString.length-8
						$int2 = [Int] $lwz_MasterString.length-1
						$tmpStringy = $lwz_MasterString.Substring($int1, 8);
						#$tmpStringy
						#write-host "temp allbytes2 -> " $tmpStringy
						#write-host "allbytes2 ! ->" $allBytes2
						$allBytes2  += [convert]::ToInt32($tmpStringy ,2);
						$lwz_MasterString = $lwz_MasterString.Substring(0,($lwz_MasterString.length-8));
						#write-host "master string2 -> " $lwz_MasterString
					}
				}
			}
			
			$lwz_MasterString
			
			write-host "master string remainder -> " $lwz_MasterString
			
			#$allBytes2
			#$allBytes2 += 17
			#$allBytes2 += 0
			#$allBytes2 += 0
			for ($j = 0; $j -lt $Data_Image.length ; $j++){
				#$allBytes += $Data_Image[$j];
			}
			$allBytes += $Data_Image[$j];
			if ($lwz_MasterString.length -gt 0){

				$allBytes2  += [convert]::ToInt32($lwz_MasterString ,2);
			}
			$lwz_MasterString = "";
			$allBytes = $allBytes[0..($allBytes.length-4)];
			$allBytes += 17
			$allBytes += 0
			$allBytes += 0
			$Data_Image = new-object Byte[] 0;
			$allBytes += $Data_ByteSize
			#$Data_Image = new-object Byte[] 0
			$pb += 1;

			$Data_bool = $false;
			$Data_ByteSize = -1
			$ext_bool = $true;
			#$fileBytes[$pb]
			write-host "- end img - "
			$fileBytes[$pb]
			
		}
	}
} while ($end -eq $false)

[io.file]::WriteAllBytes("C:\Users\Bablon\Desktop\candyk2.gif",$allBytes)
