<#
.SYNOPSIS
    Das Rückfall Ebenen Alarm Skript kann via Aufrufparameter gezielt Alarmvorlagen in DIVERA24/7 ansprechen.
   
.DESCRIPTION
    Beim Aufruf des Skriptes ist durch die angegebene 5-Ton Folge keine Adressierung von DIVERA Gruppen notwendig, da dies über die Alarmvorlagen ID gesteuert ist.
    Optional sind die Parameter für Alarm Stichwort und Alarm Text.
    Sind diese Parameter nicht belegt wird als Stichwort beispielhaft:
    FW Ort - Rückfallebene
    Wehrführer FW Ort - Rückfallebene
    ausgegeben.
    Im Alarmtext steht dann immer:
    Automatischer Alarm über Rückfallebene - keine Details vorhanden
    Die Config Datei als JSON File ist entsprechend abzulegen und im Powershell File zu referenzieren. 

    CURL: Installation unter Windows XP
    https://www.giga.de/downloads/windows-10/tipps/curl-in-windows-installieren-und-nutzen-so-gehts/
    https://curl.haxx.se/dlwiz/?type=bin&os=Win64&flav=-&ver=-&cpu=x86_64

    JSON Convert als eigene Funktion

.PARAMETER 5TonFolge
    Dieser 1. Parameter ist zwingend immer erforderlich. Darüber wird gezielt die jeweilige zugehörige Alarmvorlage alarmiert.
.PARAMETER AlarmStichwort
    Dieser Parameter kann optional als Alarmstichwort mitgeben werden.
    Ist dieser Parameter nicht belegt wird als Stichwort beispielhaft:
    FW Ort - Rückfallebene
    Wehrführer FW Ort - Rückfallebene
    ausgegeben.
.PARAMETER AlarmTextDetail
    Dieser Parameter kann optional als Alarm Text mitgeben werden.
    Bei Nichtbefüllung steht sonst im Alarmtext immer:
    Automatischer Alarm über Rückfallebene - keine Details vorhanden    
.EXAMPLE
    Aufruf Beispiel - Mindestaufrufanforderung
    VGHUMI_Divera_Fallback_Alarm.ps1 8XXXX --> Mindestaufrufanforderung
.EXAMPLE
    Aufruf mit den beiden optionalen Parametern
    VGHUMI_Divera_Fallback_Alarm.ps1 8XXXX Ölspur --> Angabe des Stichwortes
    VGHUMI_Divera_Fallback_Alarm.ps1 8XXXX Ölspur im Ortsteils XYZ --> Weitere Details im Alarmtext
.NOTES
    Author: Andreas Müller
    Last Edit: 2020-05-12
        Version 1.0.0 - 10.05.2020 - initiale Version 
        Version 1.0.1 - 11.05.2020 - Logging und Dokumentation ergänzt
        Version 1.0.2 - 12.05.2020 - Alarm Funktion ausgelagert - Sleep Timer eingefügt
        Version 1.0.3 - 13.05.2020 - JSON als Funktion erstellt wg Systemunterstützung Windows XP
                                   - Logging Ordner wird im Bedarfsfall automatisch angelegt --> Ausführenden Verzeichnis
                                   - Config File Prüfung muss auch im Ordner liegen - sonst Fehler
		Version 1.0.4 - 14.05.2020 - Config File für GroupAlarm erweitert - GroupAlarm ZusatzAlarm integriert
        Version 1.0.5 - 18.05.2020 - Anpassung URL Aufruf mit WinXP-WebRequest Helper Funktion
        Version 1.0.6 - 04.06.2020 - Doppelter Aufruf verhindern via Log File
        Version 1.0.7 - 23.06.2020 - Logging Erweirtert - Config File um Einheiten Art erweitert - Prüfungsfehler mit Einheitenart korrigiert
	*   Version 1.0.8 - 26.08.2020 - Abfrage aller nicht archivierter Einsätze - Funktion erweitert geändert - Logging erweitert - Umstrukturierung neuer Rechner
	    Version 1.0.9 - XX.XX.2020 - In Entwicklung: 


#>





#Pseudocode
#Aufruf Parameter 5-Ton
#0 Get Config File with Parameters & IDs
#1. Get Last Alarm All
#2. Schreibe in JSON Objekt wenn vorhanden
#3. Bei keinem Einsatz Einzel Batch aufrufen
#4. Alarm in JSON schreiben
#5. In JSON nach Untereinheit bzw. Gruppen ID gemäß Übersetzung suchen
#6. Bei Nein Alarm




param(
  [Parameter(Mandatory = $true,Position = 0,HelpMessage = "Zwingender Aufrufparameter - hier wird die aktuell ausgewerte 5-Ton Folge mitgeben")]
  [string]$5TonFolge,
  [Parameter(Mandatory = $false,Position = 1,HelpMessage = "Optionaler Aufrufparameter - hier kann das Alarmstichwort mitgeben werden")]
  [string]$AlarmStichwort,
  [Parameter(Mandatory = $false,Position = 2,HelpMessage = "Optionaler Aufrufparameter - hier kann der komplette Alarmtext mitgeben werden")]
  [string]$AlarmTextDetail
)


##############################################   Globale Parameter  ##############################################
#ZeitVariable ab wann (Sekunden) ein Zusatzalarm ausgelöst werden soll
#[bool]$AlarmAusloesungScharf = $true
[bool]$AlarmAusloesungScharf = $false
$SekundenAbweichung = 30
$SekundenSchlafDauer = 10
$DIVERA_Accesskey='XYZ'
##############################################Globale Parameter Ende##############################################



###XP Helper Funktionen###

#Umwandlungsfunktion um JSON zu erstellen - aktuell nicht in Verwendung
function ConvertTo-Json20([object] $item){
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer
    return $ps_js.Serialize($item)
}


#Umwandlungsfunktion um JSON auszulesen
function ConvertFrom-Json20([object] $item){ 
    add-type -assembly system.web.extensions
    $ps_js=new-object system.web.script.serialization.javascriptSerializer

    #The comma operator is the array construction operator in PowerShell
    return ,$ps_js.DeserializeObject($item)
}

function WinXP-WebRequest{
    Param(
        $uri,
        $method="GET",
        $body,
        $trySSO=1,
        $customHeaders
    )
    if($script:cookiejar -eq $Null){
        $script:cookiejar = New-Object System.Net.CookieContainer     
    }
    $maxAttempts = 3
    $attempts=0
    while($true){
        $attempts++
        try{
            $retVal = @{}
            $request = [System.Net.WebRequest]::Create($uri)
            $request.TimeOut = 5000
            $request.Method = $method
            if($trySSO -eq 1){
                $request.UseDefaultCredentials = $True
            }
            if($customHeaders){
                $customHeaders.Keys | % { 
                    $request.Headers[$_] = $customHeaders.Item($_)
                }
            }
            $request.UserAgent = "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 10.0; WOW64; Trident/7.0; .NET4.0C; .NET4.0E)"
            $request.ContentType = "application/x-www-form-urlencoded"
            $request.CookieContainer = $script:cookiejar
            if($method -eq "POST"){
                $body = [byte[]][char[]]$body
                $upStream = $request.GetRequestStream()
                $upStream.Write($body, 0, $body.Length)
                $upStream.Flush()
                $upStream.Close()
            }
            $response = $request.GetResponse()
            $retVal.StatusCode = $response.StatusCode
            $retVal.StatusDescription = $response.StatusDescription
            $retVal.Headers = $response.Headers
            $stream = $response.GetResponseStream()
            $streamReader = [System.IO.StreamReader]($stream)
            $retVal.Content = $streamReader.ReadToEnd()
            $streamReader.Close()
            $response.Close()
            return $retVal
        }catch{
            if($attempts -ge $maxAttempts){Throw}else{sleep -s 2}
        }
    }
}
###Ende XP Helper Funktionen ###



###Globale Log Funktion####
# Funktion zum Erzeugen der einzelnen LogEinträge            
function write-AlarmLogRecord
{
  param
  (
    [ValidateSet("INFO","WARNING","ERROR","DEBUG")]
    [string]$Typ = "INFO",
    [ValidateNotNullOrEmpty()]
    [string]$Text
  )

  # Generieren des Zeitstempels für die einzelnen LogZeilen            
  $TimeStamp = Get-Date -Format "[dd.MM.yyyy HH:mm:ss]"

  # Inhalt entsprechend Formatieren und zusammensetzen            
  $LogInhalt = "{0,-25}{1,-12}{2}" -f $TimeStamp,$Typ,$Text

  # Hinzufügen zum LogFile            
  Add-Content $Logfile $LogInhalt
}

# Funktion zum Erzeugen des Rückfall Alarms
function set-AlarmRueckfall
{
  param
  (
    [bool]$AlarmAusloesungScharf = $false,
    [string]$AlarmVorlage,
    [string]$GroupAlarmCode,
    [string]$AlarmStichwort,
    [string]$AlarmTextDetail

  )
  [bool]$AlarmStichwortBool = $false;
  [bool]$AlarmTextDetailBool = $false;
  if ($AlarmStichwort -ne '')
  {
    write-AlarmLogRecord -Typ INFO $AlarmStichwort
    $AlarmStichwort = 'title=' + $AlarmStichwort
    $AlarmStichwortBool = $true;
  }
  if ($AlarmTextDetail -ne '')
  {
    write-AlarmLogRecord -Typ INFO $AlarmTextDetail
    $AlarmTextDetail = 'text=' + $AlarmTextDetail
    $AlarmTextDetailBool = $true;
  }

  if($AktuelleEinheitGroupAlarmListCode -ne '###' -and $AlarmAusloesungScharf -eq $true)
  {
    $GroupAlarmInfo = 'GroupAlarmcode: '+ $AktuelleEinheitGroupAlarmListCode
    write-AlarmLogRecord -Typ INFO $GroupAlarmInfo
    
    $GroupAlarmLink = 'https://www.groupalarm.de/webin.php?&log_user=emmelshausen&log_epass=421d06150e9f5fe57e584b9c96d28ab5fdc267070f702dc74be696561d9fdbc4&'
    $GroupAlarmLink +=$AktuelleEinheitGroupAlarmListCode
    $GroupAlarmLink +='&fb=1'

    #Windows 10 Web Aufruf:
    #curl $GroupAlarmLink -s
    #Windows XP Web Aufruf:
    #WinXP-WebRequest $GroupAlarmLink
        
    
    #write-AlarmLogRecord -Typ INFO 'Group Alarm Auslösung erforderlich und erfolgt'
  }
  else
  {
    write-AlarmLogRecord -Typ INFO 'Group Alarm Auslösung nicht erforderlich! Oder kein Code vorhanden'
  }
  write-AlarmLogRecord -Typ INFO $AlarmVorlage

  if ($AlarmAusloesungScharf -eq $true)
  {

    if ($AlarmStichwortBool -eq $true -and $AlarmTextDetailBool -eq $true)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmStichwort + "&" + $AlarmTextDetail + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      curl $AlarmAufrufUrl
      
      #Windows XP Web Aufruf:
      #WinXP-WebRequest $AlarmAufrufUrl


      write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst mit Stichwort und Textdetail!'
      write-AlarmLogRecord -Typ INFO 'Ende'
      check-ScriptDuplicationTestSetterRemover $5TonFolge
      exit
    }
    if ($AlarmStichwortBool -eq $true -and $AlarmTextDetailBool -eq $false)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmStichwort + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      curl $AlarmAufrufUrl
      
      #Windows XP Web Aufruf:
      #WinXP-WebRequest $AlarmAufrufUrl
      
      write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst mit Stichwort!'
      write-AlarmLogRecord -Typ INFO 'Ende'
      check-ScriptDuplicationTestSetterRemover $5TonFolge
      exit
    }
    if ($AlarmStichwortBool -eq $false -and $AlarmTextDetailBool -eq $true)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&" + $AlarmTextDetail + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      curl $AlarmAufrufUrl
      
      #Windows XP Web Aufruf:
      #WinXP-WebRequest $AlarmAufrufUrl
      
      write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst mit Textdetail!'
      write-AlarmLogRecord -Typ INFO 'Ende'
      check-ScriptDuplicationTestSetterRemover $5TonFolge
      exit
    }
    if ($AlarmStichwortBool -eq $false -and $AlarmTextDetailBool -eq $false)
    {
      $AlarmAufrufUrl = "https://www.divera247.com/api/alarm?alarmcode_id=" + $AlarmVorlage + "&accesskey="+$DIVERA_Accesskey

      #Windows 10 Web Aufruf:
      curl $AlarmAufrufUrl
      
      #Windows XP Web Aufruf:
      #WinXP-WebRequest $AlarmAufrufUrl

      write-AlarmLogRecord -Typ INFO 'Alarm ausgelöst ohne weitere Details!'
      write-AlarmLogRecord -Typ INFO 'Ende'
      check-ScriptDuplicationTestSetterRemover $5TonFolge
      exit
    }
  }
  else
  {
    write-AlarmLogRecord -Typ INFO 'Alarm nur via Log Durchlauf ausgelöst da Debug an!'
    write-AlarmLogRecord -Typ INFO 'Ende'
    check-ScriptDuplicationTestSetterRemover $5TonFolge
	exit
  }

}


function check-ScriptDuplicationTestSetter
{
  param
    (
    [string]$5TonFolge
    )

    $CurrentPath = Get-Location
    $Current5TonPath = $CurrentPath.Path + '\'+$5TonFolge+'ScriptRunning.txt'
    If(!(test-path $Current5TonPath))
    {
        New-Item -ItemType File -Force -Path $Current5TonPath
        Write-Host '1. Aufruf des Skripts - weiter gehts'
    }
    else
    {
        Write-Host 'Skript Abbruch wg. mehrfachen Aufruf'
        exit
    }
}

function check-ScriptDuplicationTestSetterRemover
{
  param
    (
    [string]$5TonFolge
    )
    $CurrentPath = Get-Location
    $Current5TonPath = $CurrentPath.Path + '\'+$5TonFolge+'ScriptRunning.txt'
    If((test-path $Current5TonPath))
    {
    Remove-Item $Current5TonPath
    Write-Host 'File gelöscht'
    }
    else
    {
    Write-Host 'kein File vorhanden'
    }
}




#$ConfigFilePath = "C:\XXX\XXX\VG-HUMI-DIVERA-Einheiten-Gruppen.txt"
$ConfigFilePath = Get-Location
$ConfigFilePath = $ConfigFilePath.Path + '\' + 'VG-HUMI-DIVERA-Einheiten-Gruppen.txt'
# Pfad zum Ablegen der LogDateien            
#$LogPfad = "C:\XXX\XXX\Logs"
$LogPfad = Get-Location
$LogPfad = $LogPfad.Path + '\' +'Logs'
If(!(test-path $LogPfad))
{
      New-Item -ItemType Directory -Force -Path $LogPfad
}
else
{
#nix zu tun 
#Write-Host 'Log bereits vorhanden'
}

If(!(test-path $ConfigFilePath))
{
Write-Host 'Config File nicht vorhanden!'
Write-Host 'Datei:VG-HUMI-DIVERA-Einheiten-Gruppen.txt muss im gleichen Verzeichnis wie Skript liegen'
Write-Host 'Skript wird abgebrochen'
exit
}


# Datum generieren. Mit diesem Beispiel wird pro Tag eine Logdatei erstellt            
$LogDatum = Get-Date -Format "yyyy-MM-dd"


###Globale Parameter Ende ###

###Check Aufruf Parameter ###
if ($5TonFolge -eq '' -or $5TonFolge.Length -ne 5)
{
  if ($5TonFolge -eq 'FEZ')
  {
      Write-Host 'Aufruf über FEZ'
      Write-Host 'weiterausbauen-funktionsaufruf-abfrage parameter etc-aufruf ortskennung zb'
      exit
  }
  else
  {
      Write-Host 'Funktionsabbruch falscher Aufruf - die 5-Ton Folge muss zwingend mit übergeben werden!'
      exit
  }
}
else
{
  $SchleifenParameter = $5TonFolge # 5-Ton-Folge aus FMS32
  #title=EinsatzTitel&text=EinsatzText
}

#Check Ob Instanz schon läuft

check-ScriptDuplicationTestSetter $5TonFolge

###Check Aufruf Parameter Ende ###


###Check LogFileExists###
# LogFile Prüfen und erstellen falls nicht vorhanden


$CompleteLogPath = $LogPfad + "\" + $LogDatum + "_" + $5TonFolge + "_AlarmLogFile.txt"

if (!(Test-Path ($CompleteLogPath)))
{
  # Erstellen des LogFiles            
  $Logfile = (New-Item ($CompleteLogPath) -ItemType File -Force).FullName

  # Überschrift für das LogFile            
  Add-Content $Logfile ("Die Alarm LogDatei wurde erstellt am $(get-date -Format "dddd dd. MMMM yyyy HH:mm:ss") Uhr`n").ToUpper()

  # Leerzeilen einfügen            
  Add-Content $Logfile "`n`n"

  # Spaltenüberschrift generieren            
  $LogInhalt = "{0,-25}{1,-12}{2}" -f "Zeitstempel","Typ","Logtext"

  # Überschrift dem Logfile hinzufügen            
  Add-Content $Logfile $LogInhalt
}
else
{
  # Falls Logfile schon vorhanden, Datei in die Variabel $Logfile aufnehmen            
  $Logfile = (Get-Item ($CompleteLogPath)).FullName

}

###Check LogFileExists Ende###






$ConfigFile = Get-Content -Encoding UTF8 $ConfigFilePath
# Anpassung als eigene Funktion wg. alter PS

$ConfigEinheitenJSON = $ConfigFile | ConvertFrom-Json

#$ConfigEinheitenJSON = ConvertFrom-Json20 $Con$5figFile

$AktuelleEinheit = $ConfigEinheitenJSON.Einheiten | Where-Object { $_.SchleifenID -eq $SchleifenParameter }
$AktuelleEinheitAlarmvorlageID = $AktuelleEinheit.AlarmVorlagenID
$AktuelleEinheitGruppenID = $AktuelleEinheit.UntereinheitGruppenID
$AktuelleEinheitName = $AktuelleEinheit.FeuerwehrGruppe
$AktuelleEinheitSchleife = $AktuelleEinheit.SchleifenID
$AktuelleEinheitGroupAlarmListCode = $AktuelleEinheit.GroupAlarmListCode
$AktuelleEinheitArt = $AktuelleEinheit.EinheitArt

$StartScriptDate = Get-Date
$AlarmStartInfo = "`r`n"
$AlarmStartInfo += "##### Info der alarmierten Einheit #####"
$AlarmStartInfo += "`r`nAlarmierte Einheit: " + $AktuelleEinheitName
$AlarmStartInfo += "`r`n5-TonSchleife: " + $AktuelleEinheitSchleife
$AlarmStartInfo += "`r`nDIVERA-Gruppen-Einheit-ID: " + $AktuelleEinheitGruppenID
$AlarmStartInfo += "`r`nAlarm-Vorlagen-ID: " + $AktuelleEinheitAlarmvorlageID
$AlarmStartInfo += "`r`nAlarm-GroupAlarmListCode: " + $AktuelleEinheitGroupAlarmListCode
$AlarmStartInfo += "`r`nAktuelle Einheiten Art: "+$AktuelleEinheitArt
$AlarmStartInfo += "`r`n##### Beginne mit weiterer Auswertung #####"
write-AlarmLogRecord -Typ INFO $AlarmStartInfo
write-AlarmLogRecord -Typ INFO 'Warte'
Start-Sleep -s $SekundenSchlafDauer
write-AlarmLogRecord -Typ INFO 'Warte Ende'
write-AlarmLogRecord -Typ INFO 'Checke letzten Alarm für Einheit'
#Gruppen oder Einheiten ID

#1.
##$alarmdatacheck = 'https://www.divera247.com/api/last-alarm?accesskey=XYZ'
#geänderter Funktionsaufruf
$alarmdatacheck = 'https://www.divera247.com/api/v2/alarms?accesskey='+$DIVERA_Accesskey


#Windows 10 Aufruf:
$alarmdatacheck = curl $alarmdatacheck
#Windows 10 JSON:
$lastalarmdatacheckjson = $alarmdatacheck.Content | ConvertFrom-Json


#Windows XP Webaufruf:
#$alarmdatacheck=WinXP-WebRequest $alarmdatacheck


#Windows XP Anpassung ConvertFrom-JSON
#$lastalarmdatacheckjson = ConvertFrom-Json20 $alarmdatacheck.Content
$sucessful = $lastalarmdatacheckjson.success
$TestItemArray = $lastalarmdatacheckjson.data.items



if($TestItemArray -ne "" -and $sucessful)
{
	$LastAlarmInfo = "Aktueller Alarm liegt an - weitere Prüfung erfolgt!"
    write-AlarmLogRecord -Typ INFO $LastAlarmInfo
    [bool]$EinheitUntereinheitAlarmiert = $false
	[bool]$EinheitGruppeAlarmiert = $false
    $Durchlauf = 0
	foreach ($ItemEinsatz in $lastalarmdatacheckjson.data.items.PSObject.Properties)
    {
	$EinsatzID=$ItemEinsatz.Name
    write-AlarmLogRecord -Typ INFO $EinsatzID
	$ItemEinsatzJSON = $lastalarmdatacheckjson.data.items.psobject.properties.Where({$_.name -eq $EinsatzID}).value
	#write-AlarmLogRecord -Typ INFO $ItemEinsatzJSON
    write-AlarmLogRecord -Typ INFO $AktuelleEinheitArt
    if ($AktuelleEinheitArt -eq 'Untereinheit')
    {
		$EinheitUntereinheitAlarmiert = $ItemEinsatzJSON.cluster.Contains($AktuelleEinheitGruppenID)
        $InfoUntereinheitAlarmiert = 'Untereinheit Alarmiert ' + $EinheitUntereinheitAlarmiert
        write-AlarmLogRecord -Typ INFO $InfoUntereinheitAlarmiert
    }
    else
	{
		$EinheitGruppeAlarmiert = $ItemEinsatzJSON.group.Contains($AktuelleEinheitGruppenID)
        $InfoGruppeAlarmiert = 'Gruppe Alarmiert ' + $EinheitGruppeAlarmiert
        write-AlarmLogRecord -Typ INFO $InfoGruppeAlarmiert
	}

    $Durchlauf = $Durchlauf + 1
    if ($EinheitUntereinheitAlarmiert -or  $EinheitGruppeAlarmiert){
        break
    }
    }
	$DurchlaufInfo = 'Anzahl der Durchläufe '+$Durchlauf
    

	write-AlarmLogRecord -Typ INFO $DurchlaufInfo
    #Bereich ob Zusatzalarm erfolgen muss
	write-AlarmLogRecord -Typ INFO 'Prüfung ob Zusatzalarm erfolgen muss'
    if ($AktuelleEinheitArt -eq 'Untereinheit' -and !$EinheitUntereinheitAlarmiert)
    {
        #Alarm da weder Gruppe noch Einheit alarmiert ist
        [bool]$AlarmRueckfallSetzen = $true;
        $AlarmInfoText = 'Es muss ein manueller Alarm über die Rückfallebene gesetzt werden, da die aktuelle UnterEinheit nicht im aktuellen Alarm enthalten ist!' + ' Variablenwert:' + $AlarmRueckfallSetzen
        write-AlarmLogRecord -Typ INFO $AktuelleEinheitAlarmvorlageID
        set-AlarmRueckfall $AlarmAusloesungScharf $AktuelleEinheitAlarmvorlageID $AktuelleEinheitGroupAlarmListCode $AlarmStichwort $AlarmTextDetail
        write-AlarmLogRecord -Typ INFO $AlarmInfoText
    }
    if ($AktuelleEinheitArt -eq 'Gruppe' -and !$EinheitGruppeAlarmiert)
    {
        #Alarm da weder Gruppe noch Einheit alarmiert ist
        [bool]$AlarmRueckfallSetzen = $true;
        $AlarmInfoText = 'Es muss ein manueller Alarm über die Rückfallebene gesetzt werden, da die aktuelle Gruppe nicht im aktuellen Alarm enthalten ist!' + ' Variablenwert:' + $AlarmRueckfallSetzen
        write-AlarmLogRecord -Typ INFO $AktuelleEinheitAlarmvorlageID
        set-AlarmRueckfall $AlarmAusloesungScharf $AktuelleEinheitAlarmvorlageID $AktuelleEinheitGroupAlarmListCode $AlarmStichwort $AlarmTextDetail
        write-AlarmLogRecord -Typ INFO $AlarmInfoText
    }
    
    if ($EinheitGruppeAlarmiert -or $EinheitUntereinheitAlarmiert)
    {
    #kein Alarm ggfs Notwendig
    [bool]$AlarmRueckfallSetzen = $false;
    #nochmal die Zeit Checken
    $LastAlarmInfo = "Es liegt bereits ein aktueller Alarm an - es erfolgt eine Zeitprüfung!"
    write-AlarmLogRecord -Typ INFO $LastAlarmInfo
    #####Zeitchecker######
    $DiveraDateTimeStampUnix = $ItemEinsatzJSON.ts_create
    $DiveraDateTime = Get-Date "1/1/1970"
    $DiveraDateTime = $DiveraDateTime.AddSeconds($DiveraDateTimeStampUnix).ToLocalTime()
    $DiveraDateTimeStr=$DiveraDateTime.tostring("dd-MM-yyyy HH:mm:ss")
    $DiveraDateTimeStrInfo = 'Einsatzdatum: '+$DiveraDateTimeStr
	write-AlarmLogRecord -Typ INFO $DiveraDateTimeStrInfo
    #$DiveraDateTime
    $TimespanNowDivera = New-TimeSpan –Start $DiveraDateTime –End $StartScriptDate

    $TimespanNowDiveraSeconds = $TimespanNowDivera.TotalSeconds
	write-AlarmLogRecord -Typ INFO $TimespanNowDiveraSeconds
	
		if ($TimespanNowDiveraSeconds -gt $SekundenAbweichung)
		{
		[bool]$TimeSpanTooGreat = $true;
		$AlarmTimeInfoText = 'Es muss ein Alarm gesetzt werden, da nicht im zeitlichen Rahmen und Zusatzalarm notwendig!' + ' Zeitunterschied (Sekunden): ' + $TimespanNowDiveraSeconds +' Sek.'
		write-AlarmLogRecord -Typ INFO $AlarmTimeInfoText
		set-AlarmRueckfall $AlarmAusloesungScharf $AktuelleEinheitAlarmvorlageID $AktuelleEinheitGroupAlarmListCode $AlarmStichwort $AlarmTextDetail
		}
		else
		{
		[bool]$TimeSpanTooGreat = $false;
		$AlarmTimeInfoText = 'Es muss kein Alarm gesetzt werden, da im zeitlichen Rahmen!' + ' Zeitunterschied (Sekunden): ' + $TimespanNowDiveraSeconds +' Sek.'
		write-AlarmLogRecord -Typ INFO $AlarmTimeInfoText
		}

    #####ZeitcheckerEnde#####
	}
	check-ScriptDuplicationTestSetterRemover $5TonFolge
	exit	    
	}

else
{
  #Alarm für Schleife --> Gruppe/Untereinheit
  $AlarmInfoText = 'Es muss ein manueller Alarm über die Rückfallebene gesetzt werden - garkeine Alarme anliegend!'
  write-AlarmLogRecord -Typ INFO $AlarmInfoText

  #Komplette Details bekannt
  set-AlarmRueckfall $AlarmAusloesungScharf $AktuelleEinheitAlarmvorlageID $AktuelleEinheitGroupAlarmListCode $AlarmStichwort $AlarmTextDetail
}