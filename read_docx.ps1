Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead("C:\Users\asus\OneDrive\Desktop\Tekdarr\ThekedarConnect_Startup_Blueprint.docx")
$entry = $zip.Entries | Where-Object { $_.FullName -eq "word/document.xml" }
if ($entry) {
    $stream = $entry.Open()
    $reader = New-Object System.IO.StreamReader($stream)
    $xmlString = $reader.ReadToEnd()
    $reader.Close()
    $stream.Close()
    $xml = [xml]$xmlString
    $text = ($xml.SelectNodes("//*[local-name()='t']") | ForEach-Object { $_.InnerText }) -join " "
    Write-Output $text
}
$zip.Dispose()
