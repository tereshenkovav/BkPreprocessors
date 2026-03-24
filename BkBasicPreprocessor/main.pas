unit main ;

interface
uses SysUtils, Classes, Optional ;

type
  TMain = class
  public
    procedure Run() ;
  end;

implementation
uses Generics.Collections, Math, LineNumerator, Version,
  SourceEncodings, BasicPreprocessor, ParamsParser ;

const MAINHELP = 'Preprocessor for BK-0010 Basic'#13#10+
  'Version: '+TGitVersion.TAG+#13#10+
  'Usage: input_file output_file [parameters]'#13#10+
  'Parameters:'#13#10+
  '/codepage='+NAME_UTF8+'|'+NAME_WIN1251+'|'+NAME_KOI8R+'|'+NAME_OEM866+' - input and output codepage'#13#10+
  '/autonumlines=true|false - set line numbers to non-numbered Basic source'#13#10+
  '/define=name - set name for ''$IFDEF directive'#13#10+
  '/startline=num - set initial num for autonumlines (default 10)'#13#10+
  '/stepline=num - set step for autonumlines (default 10)'#13#10+
  '/packnames=true|false - use short aliases for BASIC operators'#13#10+
  '/stripspaces=true|false - strip all space char, except string constants' ;


procedure TMain.Run() ;
var i:Integer ;
    basic:TBasicPreprocessor ;
    pairs:TStringList ;
    res:TOptional<TStringList> ;
begin
  try
    if ParamCount<2 then begin
      Writeln(MAINHELP) ;
      Halt(1) ;
    end;

    basic:=TBasicPreprocessor.Create(ParamStr(1)) ;
    pairs:=createParamPairsFromIndex(3) ;
    basic.SetParamsFromPairs(pairs) ;
    pairs.Free ;

    res:=basic.getResult() ;
    if not res.IsOk then raise Exception.Create('Preprocessor error: '+basic.getErrMsg()) ;

    res.Value.WriteBOM:=False ;
    res.Value.SaveToFile(ParamStr(2),basic.getEncoding()) ;
    res.Value.Free ;

    basic.Free ;
  except
    on E: Exception do begin
      Writeln('Error '+E.ClassName+': '+E.Message);
      Halt(1) ;
    end;
  end;
end ;

end.
