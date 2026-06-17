param(
	[string]$ConfigPath = "src/cf"
)

$ErrorActionPreference = "Stop"

function Resolve-ConfigurationFile {
	param([string]$Path)

	if (Test-Path -LiteralPath $Path -PathType Leaf) {
		return (Resolve-Path -LiteralPath $Path).Path
	}

	$candidate = Join-Path $Path "Configuration.xml"
	if (Test-Path -LiteralPath $candidate -PathType Leaf) {
		return (Resolve-Path -LiteralPath $candidate).Path
	}

	throw "Configuration.xml not found: $Path"
}

function Load-XmlFile {
	param([string]$Path)

	$xml = New-Object System.Xml.XmlDocument
	$xml.PreserveWhitespace = $true
	$xml.Load($Path)
	return $xml
}

$configurationFile = Resolve-ConfigurationFile -Path $ConfigPath
$root = Split-Path -Parent $configurationFile
$configurationXml = Load-XmlFile -Path $configurationFile

$namespaceManager = New-Object System.Xml.XmlNamespaceManager($configurationXml.NameTable)
$namespaceManager.AddNamespace("md", "http://v8.1c.ru/8.3/MDClasses")
$namespaceManager.AddNamespace("v8", "http://v8.1c.ru/8.1/data/core")

$configurationNode = $configurationXml.SelectSingleNode("/md:MetaDataObject/md:Configuration", $namespaceManager)
if ($null -eq $configurationNode) {
	throw "Configuration node not found in $configurationFile"
}

$name = $configurationNode.SelectSingleNode("md:Properties/md:Name", $namespaceManager).InnerText
$version = $configurationNode.SelectSingleNode("md:Properties/md:Version", $namespaceManager).InnerText
$compatibilityMode = $configurationNode.SelectSingleNode("md:Properties/md:CompatibilityMode", $namespaceManager).InnerText

if ([string]::IsNullOrWhiteSpace($name)) {
	throw "Configuration name is empty"
}

if ([string]::IsNullOrWhiteSpace($version)) {
	throw "Configuration version is empty"
}

if ($compatibilityMode -ne "Version8_5_1") {
	throw "Unexpected compatibility mode: $compatibilityMode"
}

$commonModulesDir = Join-Path $root "CommonModules"
$languagesDir = Join-Path $root "Languages"

if (-not (Test-Path -LiteralPath $commonModulesDir -PathType Container)) {
	throw "CommonModules directory not found: $commonModulesDir"
}

if (-not (Test-Path -LiteralPath $languagesDir -PathType Container)) {
	throw "Languages directory not found: $languagesDir"
}

$languageFiles = @(Get-ChildItem -LiteralPath $languagesDir -Filter "*.xml" -File)
if ($languageFiles.Count -lt 1) {
	throw "No language XML files found in $languagesDir"
}

$moduleFile = $null
$moduleName = $null
$serverFlag = $null

foreach ($candidate in Get-ChildItem -LiteralPath $commonModulesDir -Filter "*.xml" -File) {
	$candidateXml = Load-XmlFile -Path $candidate.FullName
	$candidateNs = New-Object System.Xml.XmlNamespaceManager($candidateXml.NameTable)
	$candidateNs.AddNamespace("md", "http://v8.1c.ru/8.3/MDClasses")
	$candidateNameNode = $candidateXml.SelectSingleNode("/md:MetaDataObject/md:CommonModule/md:Properties/md:Name", $candidateNs)
	$candidateServerNode = $candidateXml.SelectSingleNode("/md:MetaDataObject/md:CommonModule/md:Properties/md:Server", $candidateNs)

	if ($null -eq $candidateNameNode) {
		continue
	}

	$extModule = Join-Path (Join-Path $commonModulesDir $candidate.BaseName) "Ext/Module.bsl"
	if (Test-Path -LiteralPath $extModule -PathType Leaf) {
		$moduleFile = $candidate.FullName
		$moduleTextFile = $extModule
		$moduleName = $candidateNameNode.InnerText
		$serverFlag = $candidateServerNode.InnerText
		break
	}
}

if ($null -eq $moduleFile) {
	throw "Common module with Ext/Module.bsl not found"
}

if ($serverFlag -ne "true") {
	throw "Common module $moduleName must run on server"
}

$moduleText = Get-Content -LiteralPath $moduleTextFile -Raw -Encoding UTF8
$functionToken = -join ([char[]](1060, 1091, 1085, 1082, 1094, 1080, 1103))
$exportToken = -join ([char[]](1069, 1082, 1089, 1087, 1086, 1088, 1090))
$exportPattern = "$functionToken[\s\S]*?$exportToken"
$exportCount = ([regex]::Matches($moduleText, $exportPattern)).Count

if ($exportCount -lt 10) {
	throw "Expected at least 10 exported functions, found $exportCount"
}

Write-Host "Validation OK: Configuration.$name v$version, module $moduleName, exports $exportCount"
