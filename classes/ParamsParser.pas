unit ParamsParser ;

interface
uses Classes, SysUtils ;

function createParamPairsFromIndex(start:Integer):TStringList ;

implementation

function createParamPairsFromIndex(start:Integer):TStringList ;
var i,p:Integer ;
begin
  Result:=TStringList.Create() ;
  for i := start to ParamCount do begin
    if ParamStr(i)[1]<>'/' then raise Exception.Create('Unknown argument: '+ParamStr(i)+', use /name=value') ;
    p:=ParamStr(i).IndexOf('=') ;
    if p=-1 then raise Exception.Create('Unknown argument: '+ParamStr(i)+', use /name=value') ;
    Result.AddPair(ParamStr(i).Substring(1,p-1),ParamStr(i).Substring(p+1)) ;
  end;
end;

end.