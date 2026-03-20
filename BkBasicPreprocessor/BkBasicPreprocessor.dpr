program BkBasicPreprocessor;

{$APPTYPE CONSOLE}

uses
  main,
  LineNumerator in '..\classes\LineNumerator.pas',
  Optional in '..\classes\Optional.pas',
  SourceEncodings in '..\classes\SourceEncodings.pas' ;

begin
  with TMain.Create() do begin
    Run() ;
    Free ;
  end;
end.

