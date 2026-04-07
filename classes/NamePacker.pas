unit NamePacker;

interface
uses Classes ;

type
  TNamePacker = class
  private
    lines:TStringList ;
    aliases:TStringList ;
  public
    constructor Create(Alines:TStringList; str_aliases:string) ;
    destructor Destroy; override ;
    function getPackedLines():TStringList ;
  end;

const BASIC_NAME_ALIASES =
'AUTO=AU'#13#10+
'DIM=DI'#13#10+
'PAINT=PA'#13#10+
'BEEP=BE'#13#10+
'DRAW=DR'#13#10+
'POKE=PO'#13#10+
'BLOAD=BL'#13#10+
'FOR=FO'#13#10+
'BSAVE=BS'#13#10+
'GOSUB=GOS'#13#10+
'PSET=PS'#13#10+
'CIRCLE=CI'#13#10+
'INPUT=IN'#13#10+
'READ=REA'#13#10+
'CLEAR=CLE'#13#10+
'RENUM=REN'#13#10+
'COLOR=COL'#13#10+
'LINE=LIN'#13#10+
'RESTORE=RES'#13#10+
'CSAVE=CS'#13#10+
'MONIT=MO'#13#10+
'RETURN=RET'#13#10+
'DATA=DA'#13#10+
'NEXT=NEX'#13#10+
'STOP=ST'#13#10+
'DELETE=DEL'#13#10+
'ELSE GOTO=EL'#13#10+
'ELSE=EL'#13#10+
'THEN GOTO=TH'#13#10+
'THEN=TH'#13#10+
'STEP=ST'#13#10+
'OUT=OU'#13#10+
'PRINT=?' ;

FOCAL_NAME_ALIASES=
'ASK=A'#13#10+
'COMMENT=C'#13#10+
'DO=D'#13#10+
'ERASE=E'#13#10+
'SET=S'#13#10+
'XECUTE=X'#13#10+
'FOR=F'#13#10+
'IF=I'#13#10+
'GOTO=G'#13#10+
'QUIT=Q'#13#10+
'RETURN=R'#13#10+
'TYPE=T' ;

implementation
uses SysUtils, Generics.Collections ;

{ TNamePacker }

constructor TNamePacker.Create(Alines: TStringList; str_aliases:string);
begin
  lines:=TStringList.Create() ;
  lines.Assign(Alines) ;
  aliases:=TStringList.Create() ;
  aliases.Text:=str_aliases ;
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
