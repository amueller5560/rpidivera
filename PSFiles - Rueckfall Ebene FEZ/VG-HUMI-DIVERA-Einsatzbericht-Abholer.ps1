$DIVERA_Accesskey='iNdoc8PkMtmy4oF-6rGT6NsjZGtPxjo0Eb0ZzatvBuy2eW9urVpuNdVMZyNtpuOf'
#$LogDatum = Get-Date -Format "yyyy-MM-dd"
$PDFAblagePfad = Get-Location
$PDFAblagePfadRoot = $PDFAblagePfad.Path
#$PDFAblagePfad = $PDFAblagePfad +'\' + $LogDatum+'Einsatzberichte'


function get-AlarmBericht ($AlarmID,$AngelegterAblagePfad)
{
	
$AlarmID
$AngelegterAblagePfad
$GetPDFDataUrl = ""
$GetPDFDataUrl ="https://www.divera247.com/api/v2/alarms/download/"+$AlarmID+"?"+"accesskey="+$DIVERA_Accesskey
Write-Host "AlarmAbruf: " $GetPDFDataUrl
#Windows 10 Aufruf:
#$GetPDFDataUrlData = curl -SkipHeaderValidation $GetPDFDataUrl 
$GetPDFDataUrlData = curl $GetPDFDataUrl

$pdffilename= $GetPDFDataUrlData.RawContent
$pdffilename= $pdffilename | findstr -i 'filename'
# Dynamisch ab dem Wort "super" bis zum Ende des Strings ausgeben.            
$pdffilenameshort= $pdffilename.Substring($pdffilename.IndexOf("filename"),$pdffilename.Length-$pdffilename.IndexOf("filename")) 
$pdffilenameshort2 = $pdffilenameshort.TrimStart("filename=""")
$pdffilenamefinish = $pdffilenameshort2.TrimEnd("""")
 
$AngelegterAblagePfad = $AngelegterAblagePfad + '\'+ $pdffilenamefinish
Write-Host $PDFAblagePfad
If(!(test-path $PDFAblagePfad))
	{
		[io.file]::WriteAllBytes($AngelegterAblagePfad,$GetPDFDataUrlData.Content)
	}
	else
	{
		Write-Host 'File bereits existent - springe zurück in Aufruffunktion'
		return
	}

}


function get-AllNotArchivedAlarmIDs
{
$GetAllAlarms ="https://www.divera247.com/api/v2/alarms?accesskey="+$DIVERA_Accesskey
#Windows 10 Aufruf:
$alarmdatacheck = curl $GetAllAlarms
#Windows 10 JSON:
$lastalarmdatacheckjson = $alarmdatacheck.Content | ConvertFrom-Json
$sucessful = $lastalarmdatacheckjson.success
$TestItemArray = $lastalarmdatacheckjson.data.items

	if($TestItemArray -ne "" -and $sucessful)
		{
			foreach ($ItemEinsatz in $lastalarmdatacheckjson.data.items.PSObject.Properties)
			{
				$EinsatzID=$ItemEinsatz.Name
				Write-Host $EinsatzID
				$ItemEinsatzJSON = $lastalarmdatacheckjson.data.items.psobject.properties.Where({$_.name -eq $EinsatzID}).value
				$EinsatzClosed = $ItemEinsatzJSON.closed
				Write-Host 'Einsatz ist geschlossen? ' + $EinsatzClosed
				if($EinsatzClosed -eq $true)
				{
					$DiveraDateTimeStampUnix = $ItemEinsatzJSON.ts_create
					$DiveraDateTime = Get-Date "1/1/1970"
					$DiveraDateTime = $DiveraDateTime.AddSeconds($DiveraDateTimeStampUnix).ToLocalTime()
					$DiveraDateTimeStr=$DiveraDateTime.tostring("yyyy-MM-dd")
					#Checke Pfad
					$PDFAblagePfad = $PDFAblagePfadRoot +'\' + $DiveraDateTimeStr+'_Einsatzberichte'
					Write-Host $PDFAblagePfad
                    #$DiveraDateTimeStrInfo = 'Einsatzdatum: '+$DiveraDateTimeStr
					If(!(test-path $PDFAblagePfad))
					{
					New-Item -ItemType Directory -Force -Path $PDFAblagePfad
					}

					get-AlarmBericht $EinsatzID $PDFAblagePfad
					Write-Host 'Einsatzbericht abgeholt'
				}
				else
				{
					Write-Host 'Einsatz noch offen'
					continue
				}
			}
		}
	else
		{
			Write-Host 'Keine Einsätze vorhanden'
			#exit
		}
}

get-AllNotArchivedAlarmIDs