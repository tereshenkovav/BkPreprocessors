unit main ;

interface
uses SysUtils, Classes ;

type
  TMain = class
  public
    procedure Run() ;
  end;

implementation
uses SourceEncodings, Optional, Version, FocalPreprocessor, ParamsParser ;

const MAINHELP = 'Preprocessor for BK-0010 Focal'#13#10+
  'Version: '+TGitVersion.TAG+#13#10+
  'Usage: input_file output_file [parameters]'#13#10+
  'Parameters:'#13#10+
  '/codepage='+NAME_UTF8+'|'+NAME_WIN1251+'|'+NAME_KOI8R+'|'+NAME_OEM866+' - input and output codepage'#13#10+
  '/define=name - set name for ''$IFDEF directive'#13#10+
  '/packnames=true|false - use short aliases for FOCAL operators' ;

procedure TMain.Run() ;
var focal:TFocalPreprocessor ;
    pairs:TStringList ;
    res:TOptional<TStringList> ;
begin
  try
    if ParamCount<2 then begin
      Writeln(MAINHELP) ;
      Halt(1) ;
    end;

    focal:=TFocalPreprocessor.Create(ParamStr(1)) ;
    pairs:=createParamPairsFromIndex(3) ;
    focal.SetParamsFromPairs(pairs) ;
    pairs.Free ;

    res:=focal.getResult() ;
    if not res.IsOk then raise Exception.Create('Preprocessor error: '+focal.getErrMsg()) ;

    res.Value.WriteBOM:=False ;
    res.Value.SaveToFile(ParamStr(2),focal.getEncoding()) ;
    res.Value.Free ;

    focal.Free ;
  except
    on E: Exception do begin
      Writeln('Error '+E.ClassName+': '+E.Message);
      Halt(1) ;
    end;
  end;
end ;

end.