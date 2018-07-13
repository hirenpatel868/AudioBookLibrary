[CmdletBinding()]
param (
	[string]$CatalogUrl = 'http://oszkapi-dev.azurewebsites.net/api/audiobooks',
	[string]$CatalogFile = './mobile/src/main/res/raw/offline_ebook_list.txt',
	[string]$File = './mobile/src/main/res/raw/offline_catalog.json'
)

cd $PSScriptRoot

$catalog = @()
$audioBooks = Get-Content -Path $CatalogFile 
#$audioBooks = Invoke-RestMethod $CatalogUrl | Select-Object -First 2

$count = 0
foreach ($book in $audioBooks) {
	$count++
	$id = $book.Split("/")[-1]
	Write-Host "$count - Processing $($id).." -ForegroundColor Magenta

	$ebookObject = New-Object psobject -Property @{
		title=''
		image="$book/borito.jpg" # $book.thumbnailUrl
		album='' # $book.fullTitle
		artist=''
		genre='Novella'
		source=''
		trackNumber=0
		totalTrackCount=0
		duration=0
		site=''
	}

	
	#$trackUrl = "$CatalogUrl/$($book.id)"
	$trackUrl = "$CatalogUrl/$($id)"
	$ebookObject.site = $trackUrl
	
    Write-Host "`t $trackUrl" -ForegroundColor Magenta

    # Get Audiobook details
    $trackDetails = $null
	$trackDetails = Invoke-RestMethod $trackUrl

	Write-Verbose "Adding fullTitle"
	#if ($trackDetails | Get-Member fullTitle) { $ebookObject.album = $trackDetails.fullTitle }
	if ($trackDetails | Get-Member author) { $ebookObject.artist = $trackDetails.author }
	if ($trackDetails | Get-Member title) { $ebookObject.album = $trackDetails.title }

	try {
		if ($trackDetails.creators[0].isFamilyFirst -eq $false) {
			$ebookObject.artist = $ebookObject.artist + "," + $trackDetails.creators[0].familyName + " " +  $trackDetails.creators[0].givenName
		}
		Write-Warning "Expanded name to $($ebookObject.artist)"
	} catch {
		$_  | Out-Null
	}

	#if ($trackDetails.fullTitle -match ':') {
	#	Write-Verbose "Splitting fullTitle"
	#	$ebookObject.album = $trackDetails.fullTitle.Split(':')[1].Trim()
	#	$ebookObject.artist = $trackDetails.fullTitle.Split(':')[0].Trim()
	#}

    # Override Author
    #if ($trackDetails | Get-Member author) { $ebookObject.artist = $trackDetails.author }

    # Override Genre
    if ($trackDetails | Get-Member type) {
        $ebookObject.genre = [string]::Join(',',($trackDetails.type | where { $_ -notmatch 'hang'}))
    }

    # Populate tracks
	$trackNumber = 0
	foreach ($t in $trackDetails.tracks) {
		$trackNumber++
		$trackObject = $ebookObject.psobject.Copy()
		$trackObject.title = $t.title
		$trackObject.source = $t.fileUrl
		$trackObject.trackNumber = $trackNumber
		$trackObject.totalTrackCount = $trackDetails.tracks | Measure-Object | Select-Object -Expand Count

        if ($t | Get-Member lengthTotalSeconds) {
            $trackObject.duration = $t.lengthTotalSeconds
        }

		$catalog += $trackObject
		$trackObject
	}
	if ($trackNumber -eq 0) {
		Write-Error "No tracks found for $($t.title) on $trackUrl"
	}
}
$sortedProperty = ($catalog[0] | Get-Member -Type NoteProperty | Select-Object -Expand Name)

$sorted = New-object psobject -Property @{music=$catalog}
$sorted.music = $sorted.music | Sort-Object image,trackNumber,source | Select-Object -Property $sortedProperty
Set-Content -Path $File -Value ($sorted | ConvertTo-Json) -Force -Encoding UTF8
