@echo off
for /F %%i in ('git tag --list --sort=committerdate') do set BUILDTAG=%%i
for /F %%i in ('git rev-parse HEAD') do set BUILDCOMMIT=%%i
set BUILDCOMMIT=%BUILDCOMMIT:~0,8%
for /F %%i in ('git branch --show-current') do set BUILDBRANCH=%%i

echo %BUILDTAG% %BUILDCOMMIT% %BUILDBRANCH%

echo unit Version ;  > ..\classes\Version.pas
echo interface >> ..\classes\Version.pas
echo type TGitVersion = class >> ..\classes\Version.pas
echo const COMMIT = '%BUILDCOMMIT%'; >> ..\classes\Version.pas
echo const BRANCH = '%BUILDBRANCH%'; >> ..\classes\Version.pas
echo const TAG = '%BUILDTAG%'; >> ..\classes\Version.pas
echo end ; >> ..\classes\Version.pas
echo implementation >> ..\classes\Version.pas
echo end. >> ..\classes\Version.pas
