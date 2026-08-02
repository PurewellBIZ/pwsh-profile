#!/usr/bin/env pwsh
# 아이콘/이미지 관련 유틸리티를 모아둔 스크립트입니다.
# 필요하면 직접 불러와도 됩니다: . "$PWSHLibraryPath\IconManipulate.ps1"

function ConvertTo-ICO {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, Position = 0)]
    [string]$InputPath,

    [Parameter(Position = 1)]
    [string]$OutputPath,

    [string]$Sizes = "256,128,64,48,32,16"
  )

  begin {
    $imageMagickCommand = $null

    foreach ($candidate in @("magick", "convert")) {
      if (Get-Command $candidate -ErrorAction SilentlyContinue) {
        $imageMagickCommand = $candidate
        break
      }
    }

    if (-not $imageMagickCommand) {
      Write-Error "ImageMagick 명령을 찾을 수 없습니다. 'magick' 또는 'convert'가 설치되어 있는지 확인해 주세요."
      return
    }
  }

  process {
    $resolvedInputPath = $InputPath
    if (-not [System.IO.Path]::IsPathRooted($resolvedInputPath)) {
      $resolvedInputPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $resolvedInputPath))
    }

    $file = Get-Item -Path $resolvedInputPath -ErrorAction SilentlyContinue
    if (-not $file -or -not $file.Exists) {
      Write-Error "파일을 찾을 수 없습니다: $InputPath"
      return
    }

    if (-not $OutputPath) {
      $OutputPath = [System.IO.Path]::ChangeExtension($file.FullName, ".ico")
    }
    elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
      $OutputPath = [System.IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
    }

    $outputDirectory = Split-Path -Path $OutputPath -Parent
    if ($outputDirectory) {
      New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
    }

    $magickArgs = @()

    if ($file.Extension -eq ".svg") {
      $magickArgs += @("-background", "none")
    }

    $magickArgs += @(
      $file.FullName,
      "-define", "icon:auto-resize=$Sizes",
      $OutputPath
    )

    Write-Host "'$($file.Name)' -> '$([System.IO.Path]::GetFileName($OutputPath))' 변환 중..." -ForegroundColor Cyan
    & $imageMagickCommand @magickArgs

    if ($LASTEXITCODE -eq 0) {
      Write-Host "변환 완료!" -ForegroundColor Green
    }
    else {
      Write-Error "변환 실패 (Exit Code: $LASTEXITCODE)"
    }
  }
}

function New-IconLibrary {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$IconFolder,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$OutputDllPath,

    # 리소스 빌더 도구를 강제로 다시 빌드하고 싶을 때 사용
    [switch]$ForceRebuildTool,

    # 출력 경로에 이미 dll이 있어도 강제로 다시 빌드해서 덮어쓸 때 사용
    [switch]$Force
  )

  # 1. 아이콘 파일 탐색 (ABC순 정렬 -> 정렬된 순서의 첫 번째 아이콘이 그룹ID 101을 받아
  #    dll의 "기본 아이콘"(인덱스 0)이 된다. 아이콘을 추가/삭제해도 항상 이름순으로
  #    결정되므로 결과가 매번 일관적이다.)
  $icons = Get-ChildItem -Path $IconFolder -Filter *.ico |
  Sort-Object { $_.Name } -Culture ([System.Globalization.CultureInfo]::InvariantCulture)

  if (-not $icons -or $icons.Count -eq 0) {
    Write-Error "해당 폴더에 .ico 파일이 없습니다: $IconFolder"
    return
  }

  # 출력 파일이 이미 있는 경우 -Force 없이는 진행하지 않음
  $resolvedOutputPath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($OutputDllPath)
  if (Test-Path $resolvedOutputPath) {
    if (-not $Force) {
      Write-Error "출력 파일이 이미 존재합니다: $resolvedOutputPath`n덮어쓰려면 -Force 옵션을 사용하세요."
      return
    }
    # 읽기 전용 속성이 걸려있어도 덮어쓸 수 있도록 해제
    try {
      $existingItem = Get-Item -Path $resolvedOutputPath -Force
      if ($existingItem.Attributes -band [System.IO.FileAttributes]::ReadOnly) {
        $existingItem.Attributes = $existingItem.Attributes -band (-bnot [System.IO.FileAttributes]::ReadOnly)
      }
    }
    catch {
      Write-Error "기존 출력 파일의 속성을 변경할 수 없습니다: $($_.Exception.Message)"
      return
    }
  }

  if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    Write-Error "'dotnet' 명령어를 찾을 수 없습니다. .NET SDK가 설치되어 있는지 확인해 주세요."
    return
  }

  # ------------------------------------------------------------------
  # 2. .ico -> .res 패킹용 헬퍼 도구(ResBuilder)를 "최초 1회만" 빌드해서 캐시
  #    - 매 호출마다 dotnet run(=매번 restore+build)을 하지 않도록 함
  #    - UseAppHost=false 로 지정하여 exe용 런타임 호스트 팩(Microsoft.NETCore.App.Host.*)
  #      다운로드가 필요 없게 함 -> 네트워크가 막혀있고 dotnet SDK만 깔린 환경에서도 빌드 가능
  # ------------------------------------------------------------------
  $toolRoot = Join-Path $env:LOCALAPPDATA "IconLibraryTool"
  $builderDir = Join-Path $toolRoot "ResBuilder"
  $builderDll = Join-Path $builderDir "bin/Release/net8.0/ResBuilder.dll"

  if ($ForceRebuildTool -or -not (Test-Path $builderDll)) {
    Write-Host "리소스 빌더 도구를 준비합니다 (최초 1회만 수행됩니다)..." -ForegroundColor Cyan

    if (Test-Path $builderDir) {
      Remove-Item -Path $builderDir -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $builderDir -Force | Out-Null

    $resBuilderCode = @'
using System;
using System.IO;
using System.Collections.Generic;

class Program {
    static void Main(string[] args) {
        if (args.Length < 2) return;
        string resPath = args[0];
        string listPath = args[1];

        if (!File.Exists(listPath)) return;
        string[] icoFiles = File.ReadAllLines(listPath);

        using (FileStream fs = new FileStream(resPath, FileMode.Create, FileAccess.Write))
        using (BinaryWriter bw = new BinaryWriter(fs)) {
            // Write NULL Resource Header (32 bytes) - .res 파일 스펙상 반드시 이 값들이어야 함
            // (전부 0으로 채우면 HeaderSize=0이 되어 "malformed" 오류가 발생함)
            bw.Write((uint)0);        // DataSize = 0
            bw.Write((uint)32);       // HeaderSize = 32
            bw.Write((ushort)0xFFFF); // TYPE (0xFFFF, 0x0000)
            bw.Write((ushort)0x0000);
            bw.Write((ushort)0xFFFF); // NAME (0xFFFF, 0x0000)
            bw.Write((ushort)0x0000);
            bw.Write((uint)0);        // DataVersion
            bw.Write((ushort)0);      // MemoryFlags
            bw.Write((ushort)0);      // LanguageId
            bw.Write((uint)0);        // Version
            bw.Write((uint)0);        // Characteristics

            ushort groupHeaderId = 101;
            ushort iconImageId = 1;

            foreach (var icoPath in icoFiles) {
                string trimmedPath = icoPath.Trim();
                if (string.IsNullOrEmpty(trimmedPath) || !File.Exists(trimmedPath)) continue;

                byte[] icoBytes = File.ReadAllBytes(trimmedPath);
                if (icoBytes.Length < 6) continue;

                ushort imageCount = BitConverter.ToUInt16(icoBytes, 4);

                // Group Icon Resource Header
                MemoryStream groupStream = new MemoryStream();
                BinaryWriter groupWriter = new BinaryWriter(groupStream);

                groupWriter.Write(icoBytes, 0, 6);

                int dirOffset = 6;
                for (int i = 0; i < imageCount; i++) {
                    byte width = icoBytes[dirOffset];
                    byte height = icoBytes[dirOffset + 1];
                    byte colorCount = icoBytes[dirOffset + 2];
                    byte reserved = icoBytes[dirOffset + 3];
                    ushort planes = BitConverter.ToUInt16(icoBytes, dirOffset + 4);
                    ushort bitCount = BitConverter.ToUInt16(icoBytes, dirOffset + 6);
                    uint bytesInRes = BitConverter.ToUInt32(icoBytes, dirOffset + 8);
                    uint imageOffset = BitConverter.ToUInt32(icoBytes, dirOffset + 12);

                    groupWriter.Write(width);
                    groupWriter.Write(height);
                    groupWriter.Write(colorCount);
                    groupWriter.Write(reserved);
                    groupWriter.Write(planes);
                    groupWriter.Write(bitCount);
                    groupWriter.Write(bytesInRes);
                    groupWriter.Write(iconImageId);

                    byte[] rawImageData = new byte[bytesInRes];
                    Array.Copy(icoBytes, imageOffset, rawImageData, 0, bytesInRes);
                    WriteResourceEntry(bw, 3, iconImageId, rawImageData);

                    iconImageId++;
                    dirOffset += 16;
                }

                WriteResourceEntry(bw, 14, groupHeaderId, groupStream.ToArray());
                groupHeaderId++;
            }
        }
    }

    static void WriteResourceEntry(BinaryWriter bw, ushort typeId, ushort resId, byte[] data) {
        uint dataSize = (uint)data.Length;
        uint headerSize = 32;

        bw.Write(dataSize);
        bw.Write(headerSize);

        bw.Write((ushort)0xFFFF);
        bw.Write(typeId);

        bw.Write((ushort)0xFFFF);
        bw.Write(resId);

        bw.Write((uint)0);
        bw.Write((ushort)0x1030);
        bw.Write((ushort)0);
        bw.Write((uint)0);
        bw.Write((uint)0);

        bw.Write(data);

        int padding = (4 - (data.Length % 4)) % 4;
        if (padding > 0) bw.Write(new byte[padding]);
    }
}
'@
    $resBuilderCode | Out-File -FilePath (Join-Path $builderDir "Program.cs") -Encoding UTF8

    $builderProj = Join-Path $builderDir "ResBuilder.csproj"
    @'
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <!-- apphost(네이티브 실행파일) 생성을 끔: Microsoft.NETCore.App.Host.* 런타임 팩을
         새로 내려받을 필요가 없어져서, 오프라인/사내망처럼 dotnet SDK만 설치된
         환경에서도 안정적으로 빌드된다. 실행은 'dotnet ResBuilder.dll' 로 한다. -->
    <UseAppHost>false</UseAppHost>
    <InvariantGlobalization>true</InvariantGlobalization>
  </PropertyGroup>
</Project>
'@ | Out-File -FilePath $builderProj -Encoding UTF8

    $buildOutput = & dotnet build $builderProj -c Release --nologo -v quiet 2>&1
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path $builderDll)) {
      Write-Error "ResBuilder 도구 빌드 실패:`n$($buildOutput -join [Environment]::NewLine)"
      return
    }
  }

  # ------------------------------------------------------------------
  # 3. 임시 작업 폴더 (이번 호출의 res/list 파일 전용)
  # ------------------------------------------------------------------
  $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "IconLibBuild_$(Get-Random)"
  New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

  $resPath = Join-Path $tempDir "icons.res"
  $listPath = Join-Path $tempDir "iconlist.txt"
  $csDummy = Join-Path $tempDir "Class1.cs"
  $csprojPath = Join-Path $tempDir "IconLibrary.csproj"

  try {
    # 아이콘 파일 경로 목록을 txt 파일로 저장 (공백/특수문자 파싱 문제 완전 방지)
    $iconPaths = $icons | Select-Object -ExpandProperty FullName
    $iconPaths | Out-File -FilePath $listPath -Encoding UTF8

    Write-Host "($($icons.Count)개 아이콘) -> 네이티브 Win32 .res 패킹 중..." -ForegroundColor Cyan

    # 이미 빌드해둔 dll을 바로 실행 (dotnet run이 아님) -> restore/build 과정을
    # 다시 거치지 않으므로 빠르고, 네트워크 없는 환경에서도 안전하게 동작한다.
    $runOutput = & dotnet $builderDll "$resPath" "$listPath" 2>&1
    if ($LASTEXITCODE -ne 0) {
      Write-Error "ResBuilder 실행 실패:`n$($runOutput -join [Environment]::NewLine)"
      return
    }

    if (-not (Test-Path $resPath)) {
      Write-Error ".res 네이티브 리소스 생성에 실패했습니다."
      return
    }

    # 4. 최종 DLL 빌드
    "namespace IconLib { public class Dummy {} }" | Out-File -FilePath $csDummy -Encoding UTF8

    $csprojContent = @"
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <TargetFramework>net8.0</TargetFramework>
    <GenerateAssemblyInfo>false</GenerateAssemblyInfo>
    <EnableDefaultCompileItems>false</EnableDefaultCompileItems>
    <Win32Resource>$resPath</Win32Resource>
    <InvariantGlobalization>true</InvariantGlobalization>
  </PropertyGroup>
  <ItemGroup>
    <Compile Include="Class1.cs" />
  </ItemGroup>
</Project>
"@
    $csprojContent | Out-File -FilePath $csprojPath -Encoding UTF8

    Write-Host "DLL 컴파일 중..." -ForegroundColor Cyan
    $buildOutput2 = & dotnet build $csprojPath -c Release -o $tempDir --nologo -v quiet 2>&1

    $builtDll = Join-Path $tempDir "IconLibrary.dll"

    if ($LASTEXITCODE -eq 0 -and (Test-Path $builtDll)) {
      Copy-Item -Path $builtDll -Destination $resolvedOutputPath -Force
      Write-Host "DLL 생성 완료: '$resolvedOutputPath' (기본 아이콘: $($icons[0].Name))" -ForegroundColor Green
    }
    else {
      Write-Error "DLL 빌드 실패 (dotnet build):`n$($buildOutput2 -join [Environment]::NewLine)"
    }
  }
  finally {
    # 5. 임시 디렉토리 정돈 (도구 캐시인 $toolRoot는 삭제하지 않음 - 재사용을 위해 유지)
    Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
  }
}
