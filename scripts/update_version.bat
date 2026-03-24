@echo off
for /F %%i in ('git tag --list --sort=committerdate') do set BUILDTAG=%%i
for /F %%i in ('git rev-parse HEAD') do set BUILDCOMMIT=%%i
set BUILDCOMMIT=%BUILDCOMMIT:~0,8%
for /F %%i in ('git branch --show-current') do set BUILDBRANCH=%%i

echo %BUILDTAG% %BUILDCOMMIT% %BUILDBRANCH%

echo unit Version ;  > ..\BkBasicPreprocessor\Version.pas
echo interface >> ..\BkBasicPreprocessor\Version.pas 
echo type TGitVersion = class >> ..\BkBasicPreprocessor\Version.pas 
echo const COMMIT = '%BUILDCOMMIT%'; >> ..\BkBasicPreprocessor\Version.pas
echo const BRANCH = '%BUILDBRANCH%'; >> ..\BkBasicPreprocessor\Version.pas
echo const TAG = '%BUILDTAG%'; >> ..\BkBasicPreprocessor\Version.pas
echo end ; >> ..\BkBasicPreprocessor\Version.pas
echo implementation >> ..\BkBasicPreprocessor\Version.pas
echo end. >> ..\BkBasicPreprocessor\Version.pas
