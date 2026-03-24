unit SpaceStripper;

interface
uses Classes ;

type
  TSpaceStripper = class
  private
    lines:TStringList ;
  public
    constructor Create(Alines:TStringList) ;
    destructor Destroy; override ;
    function getStrippedLines():TStringList ;
  end;

implementation
uses SysUtils ;

{ TSpaceStripper }

constructor TSpaceStripper.Create(Alines: TStringList);
begin
  lines:=TStringList.Create() ;
  lines.Assign(Alines) ;
end;

destructor TSpaceStripper.Destroy;
begin
  lines.Free ;
  inherited Destroy;
end;

function TSpaceStripper.getStrippedLines: TStringList;
var str,newstr:string ;
    p:Integer ;
    instring:Boolean ;
begin
  Result:=TStringList.Create ;
  for str in lines do begin
    instring:=False ;
    p:=0 ;
    newstr:='' ;
    for p := 1 to str.Length do begin
      if str[p]='"' then instring:=not instring ;
      if instring or (str[p]<>#32) then newstr:=newstr+str[p] ;
    end;
    Result.Add(newstr) ;
  end ;
end;

end.
