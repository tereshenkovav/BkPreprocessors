unit SourceEncodings ;

interface
uses Optional, SysUtils ;

function getEncodingByName(const name:string):TOptional<TEncoding> ;

const NAME_UTF8 = 'utf8' ;
      NAME_WIN1251 = 'win1251' ;
      NAME_OEM866 = 'oem866' ;
      NAME_KOI8R = 'koi8r' ;

implementation

function getEncodingByName(const name:string):TOptional<TEncoding> ;
var str:string ;
begin
  str:=name.ToLower().Trim() ;
  Result:=TOptional<TEncoding>.NullOptional() ;
  if str=NAME_UTF8 then Exit(TEncoding.UTF8) ;
  if str=NAME_WIN1251 then Exit(TEncoding.GetEncoding(1251)) ;
  if str=NAME_OEM866 then Exit(TEncoding.GetEncoding(866)) ;
  if str=NAME_KOI8R then Exit(TEncoding.GetEncoding(20866)) ;
end;

end.