#---------------------------------# 
#      environment configuration  # 
#---------------------------------# 

install: 
  - cinst -y pester
      

#---------------------------------# 
#      build configuration        # 
#---------------------------------# 

build: false

#---------------------------------# 
#      test configuration         # 
#---------------------------------# 

test_script:
    - ps: |
        $testResultsFile = ".\TestsResults.xml"
        $res = Invoke-Pester -OutputFormat NUnitXml -OutputFile $testResultsFile -PassThru
        (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)", (Resolve-Path $testResultsFile))
        if ($res.FailedCount -gt 0) { 
            throw "$($res.FailedCount) tests failed."
        }

#---------------------------------# 
#      artifacts configuration    # 
#---------------------------------# 

artifacts:
  - path: lib
    name: lib
    type: zip
    
#---------------------------------# 
#      deployment configuration   # 
#---------------------------------# 

# scripts to run before deployment 
before_deploy: 
  - ps: |
      # Creating project artifact
      $stagingDirectory = (Resolve-Path ..).Path
      $zipFilePath = Join-Path $stagingDirectory "$(Split-Path $pwd -Leaf).zip"
      Add-Type -assemblyname System.IO.Compression.FileSystem
      [System.IO.Compression.ZipFile]::CreateFromDirectory($pwd, $zipFilePath)
      
      # Creating NuGet package artifact
      New-Item nuget -ItemType Directory > $null
      Push-Location
      cd lib
      nuget.exe spec
      Pop-Location
      nuget pack .\lib\Package.nuspec -outputdirectory .\nuget
      $nuGetPackagePath = (Get-ChildItem .\nuget).FullName
      
      @(
          # You can add other artifacts here
          $zipFilePath,
          $nuGetPackagePath
      ) | % { 
          Write-Host "Pushing package $_ as Appveyor artifact"
          Push-AppveyorArtifact $_
        }
  
deploy:

    # Deploying to GitHub
  - provider: GitHub
    release: AppVeyorSample-v$(appveyor_build_version)
    description: Release of AppVeyorSample-v$(appveyor_build_version)
    tag: AppVeyorSample-v$(appveyor_build_version)
    auth_token:
      secure: 1Y8dcTfYEodas1RozybiCbQeUL6tMwpaKSJyRCN0s/LTABwaOOtBAqMEy9KxXgNp
    draft: false
    prerelease: false
    on:
      branch: dev              
      # Determines whether to deploy only on regular commits or commits with tags
      appveyor_repo_tag: false 

    # Deploying to NuGet
  - provider: NuGet
    server: https://ci.appveyor.com/nuget/karol-asrhfjcon69q
    api_key:
      secure: /kAYJdDhAKj6RBpi/weLOFTCeMHI3meVHyDK/zMDZ3w=
    skip_symbols: true


#---------------------------------# 
#      global handlers            # 
#---------------------------------# 

#on_finish:
        
        
        
