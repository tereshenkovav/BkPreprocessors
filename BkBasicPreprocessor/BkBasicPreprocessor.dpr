program BkBasicPreprocessor;

{$APPTYPE CONSOLE}

uses
  main,
  LineNumerator in '..\classes\LineNumerator.pas',
  Optional in '..\classes\Optional.pas',
  SourceEncodings in '..\classes\SourceEncodings.pas',
  ParamsParser in '..\classes\ParamsParser.pas',
  BasicPreprocessor in '..\classes\BasicPreprocessor.pas',
  NamePacker in '..\classes\NamePacker.pas',
  SpaceStripper in '..\classes\SpaceStripper.pas' ;

begin
  with TMain.Create() do begin
    Run() ;
    Free ;
  end;
end.

