unit AbstractPreprocessor ;

interface
uses Classes, SysUtils, Optional ;

type
  TDefBlockState = (dbsNone,dbsThen,dbsElse) ;
  TDefBlockCommand = (dbcNone,dbcDefine,dbcElse,dbcEnd) ;

  TAbstractPreprocessor = class
  protected
    inputfile:string ;
    errmsg:string ;
    pragmaenc,paramenc:TOptional<TEncoding> ;
    deflist:TStringList ;
    function GetDefineCommandFromLine(const line:string; var defname:string):TDefBlockCommand ;
    function LoadSourceFile(const filename: string; srcenc:TEncoding): TStringList;
    function StripCommentFromLine(const line:string):string ; virtual ; abstract ;
    procedure ProcessPragmasAndComments(script:TStringList) ;
  public
    constructor Create(const Ainputfile:string) ;
    destructor Destroy ; override ;
    procedure SetEncodingFromParams(value:TEncoding) ;
    procedure AddDefine(const name:string) ;
    function getErrMsg():string ;
    function getEncoding():TEncoding ;
  end;

implementation
uses SourceEncodings, LineNumerator, NamePacker, SpaceStripper ;

{ TAbstractPreprocessor }

constructor TAbstractPreprocessor.Create(const Ainputfile: string);
begin
  inputfile:=Ainputfile ;
  pragmaenc:=TOptional<TEncoding>.NullOptional ;
  paramenc:=TOptional<TEncoding>.NullOptional ;
  deflist:=TStringList.Create() ;
end;

destructor TAbstractPreprocessor.Destroy;
begin
  deflist.Free ;
  inherited Destroy;
end;

procedure TAbstractPreprocessor.AddDefine(const name: string);
begin
  deflist.Add(name) ;
end;

function TAbstractPreprocessor.getEncoding: TEncoding;
begin
  // Кодировка по умолчанию
  Result:=TEncoding.UTF8 ;
  // Приоритет у командной строки, потом у прагмы
  if paramenc then Result:=paramenc.Value else
  if pragmaenc then Result:=pragmaenc.Value ;
end;

function TAbstractPreprocessor.getErrMsg: string;
begin
  Result:=errmsg ;
end;

procedure TAbstractPreprocessor.SetEncodingFromParams(value: TEncoding);
begin
  paramenc:=value ;
end;

function TAbstractPreprocessor.GetDefineCommandFromLine(const line: string;
  var defname: string): TDefBlockCommand;
begin
  Result:=dbcNone ;
  if line.Trim().IndexOf('''$IFDEF')=0 then begin
    Result:=dbcDefine ;
    defname:=line.Replace('''$IFDEF','').Trim().ToUpper() ;
  end;
  if line.Trim().IndexOf('''$ELSE')=0 then Result:=dbcElse ;
  if line.Trim().IndexOf('''$ENDIF')=0 then Result:=dbcEnd ;
end;

function TAbstractPreprocessor.LoadSourceFile(const filename: string; srcenc:TEncoding): TStringList;
var i:Integer ;
    j:Integer ;
    incfile:string ;
    included:TStringList ;
begin
  if not FileExists(filename) then raise Exception.Create('Not found file: '+filename);

  Result:=TStringList.Create() ;
  Result.LoadFromFile(filename,srcenc) ;
  i:=0 ;
  while i<Result.Count do begin
    if Result[i].Trim().IndexOf('''$INCLUDE:')=0 then begin
      incfile:=Result[i].Replace('''$INCLUDE:','').Replace('''','').Trim() ;
      included:=LoadSourceFile(incfile, srcenc) ;
      Result.Delete(i) ;
      for j:=0 to included.Count-1 do
        Result.Insert(i+j,included[j]) ;
      included.Free ;
    end
    else
      Inc(i) ;
  end ;
end;

procedure TAbstractPreprocessor.ProcessPragmasAndComments(script:TStringList) ;
var i:Integer ;
    currentdefblock:string ;
    currentdefblockstate:TDefBlockState ;
begin
  // Обработка условных директив и удаление комментариев
  i:=0 ;
  currentdefblock:='' ;
  currentdefblockstate:=dbsNone ;
  while i<script.Count do begin
    case GetDefineCommandFromLine(script[i],currentdefblock) of
      dbcDefine:
        if currentdefblockstate=dbsNone then
          currentdefblockstate:=dbsThen
        else
          raise Exception.Create('Multilevel $IFDEF not supported yet') ;
      dbcElse:
        if currentdefblockstate=dbsThen then
          currentdefblockstate:=dbsElse
        else
          raise Exception.Create('$ELSE without $IFDEF') ;
      dbcEnd:
        if currentdefblockstate in [dbsThen,dbsElse] then
          currentdefblockstate:=dbsNone
        else
          raise Exception.Create('$ENDIF without $ELSE or $IFDEF') ;
    end;
    script[i]:=StripCommentFromLine(script[i]).Trim() ;
    if script[i].Length=0 then script.Delete(i) else
    if (currentdefblockstate=dbsThen)and
      (deflist.IndexOf(currentdefblock)=-1) then script.Delete(i) else
    if (currentdefblockstate=dbsElse)and
      (deflist.IndexOf(currentdefblock)<>-1) then script.Delete(i) else
       Inc(i) ;
  end;
end;

end.
