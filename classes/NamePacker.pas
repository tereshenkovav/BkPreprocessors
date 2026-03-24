unit NamePacker;

interface
uses Classes ;

type
  TNamePacker = class
  private
    lines:TStringList ;
    aliases:TStringList ;
  public
    constructor Create(Alines:TStringList) ;
    destructor Destroy; override ;
    function getPackedLines():TStringList ;
  end;

implementation
uses SysUtils, Generics.Collections ;

{ TNamePacker }

const NAME_ALIASES =
'AU(TO)'#13#10+
'DI(M)'#13#10+
'PA(INT)'#13#10+
'BE(EP)'#13#10+
'DR(AW)'#13#10+
'PO(KE)'#13#10+
'BL(OAD)'#13#10+
'FO(R)'#13#10+
'BS(AVE)'#13#10+
'GOS(UB)'#13#10+
'PS(ET)'#13#10+
'CI(RCLE)'#13#10+
'IN(PUT)'#13#10+
'REA(D)'#13#10+
'CLE(AR)'#13#10+
'REN(UM)'#13#10+
'COL(OR)'#13#10+
'LIN(E)'#13#10+
'RES(TORE)'#13#10+
'CS(AVE)'#13#10+
'MO(NIT)'#13#10+
'RET(URN)'#13#10+
'DA(TA)'#13#10+
'NEX(T)'#13#10+
'ST(OP)'#13#10+
'DEL(ETE)'#13#10+
'EL(SE GOTO)'#13#10+
'EL(SE)'#13#10+
'TH(EN GOTO)'#13#10+
'TH(EN)'#13#10+
'ST(EP)'#13#10+
'OU(T)' ;

constructor TNamePacker.Create(Alines: TStringList);
var i,p:Integer ;
    s:string ;
begin
  lines:=TStringList.Create() ;
  lines.Assign(Alines) ;
  aliases:=TStringList.Create() ;
  aliases.Text:=NAME_ALIASES ;
  for i := 0 to aliases.Count-1 do begin
    s:=aliases[i] ;
    p:=s.IndexOf('(') ;
    aliases[i]:=s.Replace('(','').Replace(')','')+'='+s.Substring(0,p);
  end;
  aliases.Add('PRINT=?') ;
end;

destructor TNamePacker.Destroy;
begin
  lines.Free ;
  aliases.Free ;
  inherited Destroy;
end;

function TNamePacker.getPackedLines: TStringList;
var s,str:string ;
    i,p:Integer ;
    instring,replaced:Boolean ;
label NextStep ;
begin
  Result:=TStringList.Create ;
  for s in lines do begin
    str:=s ;
    repeat
      instring:=False ;
      replaced:=False ;
      for p := 1 to str.Length do begin
        if str[p]='"' then instring:=not instring ;
        if instring then Continue ;
        for i := 0 to aliases.Count-1 do
          if str.ToUpper().Substring(p,aliases.Names[i].Length)=aliases.Names[i] then begin
            str:=str.Substring(0,p)+aliases.ValueFromIndex[i]+
              str.Substring(p+aliases.Names[i].Length) ;
            replaced:=True ;
            goto NextStep ;
          end;
      end ;
NextStep:
    until not replaced;
    Result.Add(str) ;
  end ;
end;

end.
