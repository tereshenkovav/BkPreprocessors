program BkFocalPreprocessor;

{$APPTYPE CONSOLE}

uses
  main,
  Optional in '..\classes\Optional.pas',
  SourceEncodings in '..\classes\SourceEncodings.pas',
  ParamsParser in '..\classes\ParamsParser.pas',
  FocalPreprocessor in '..\classes\FocalPreprocessor.pas' ;

begin
  with TMain.Create() do begin
    Run() ;
    Free ;
  end;
end.


