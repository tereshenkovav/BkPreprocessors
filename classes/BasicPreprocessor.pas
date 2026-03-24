unit BasicPreprocessor ;

interface
uses Classes, SysUtils, Optional ;

type
  TDefBlockState = (dbsNone,dbsThen,dbsElse) ;
  TDefBlockCommand = (dbcNone,dbcDefine,dbcElse,dbcEnd) ;

  TBasicPreprocessor = class
  private
    inputfile:string ;
    errmsg:string ;
    pragmaenc,paramenc:TOptional<TEncoding> ;
    autonumlines:Boolean ;
    packnames:Boolean ;
    stripspaces:Boolean ;
    deflist:TStringList ;
    startline,stepline:Integer ;
    function GetDefineCommandFromLine(const line:string; var defname:string):TDefBlockCommand ;
    function StripCommentFromLine(const line:string):string ;
    procedure UpdateParamsByPragmas() ;
    function LoadSourceFile(const filename: string; srcenc:TEncoding): TStringList;
  public
    constructor Create(const Ainputfile:string) ;
    destructor Destroy ; override ;
    procedure SetParamsFromPairs(pairs:TStringList) ;
    procedure SetEncodingFromParams(value:TEncoding) ;
    procedure EnableAutonumerates(value:Boolean) ;
    procedure EnablePackNames(value:Boolean) ;
    procedure EnableStripSpaces(value:Boolean) ;
    procedure AddDefine(const name:string) ;
    procedure SetStartLine(value:Integer) ;
    procedure SetStepLine(value:Integer) ;
    function getResult():TOptional<TStringList> ;
    function getErrMsg():string ;
    function getEncoding():TEncoding ;
  end;

implementation
uses SourceEncodings, LineNumerator, NamePacker, SpaceStripper ;

{ TBasicPreprocessor }

constructor TBasicPreprocessor.Create(const Ainputfile: string);
begin
  inputfile:=Ainputfile ;
  pragmaenc:=TOptional<TEncoding>.NullOptional ;
  paramenc:=TOptional<TEncoding>.NullOptional ;
  autonumlines:=False ;
  packnames:=False ;
  startline:=10 ;
  stepline:=10 ;
  deflist:=TStringList.Create() ;
end;

destructor TBasicPreprocessor.Destroy;
begin
  deflist.Free ;
  inherited Destroy;
end;

procedure TBasicPreprocessor.AddDefine(const name: string);
begin
  deflist.Add(name) ;
end;

procedure TBasicPreprocessor.EnableAutonumerates(value:Boolean);
begin
  autonumlines:=value ;
end;

procedure TBasicPreprocessor.EnablePackNames(value: Boolean);
begin
  packnames:=Value ;
end;

procedure TBasicPreprocessor.EnableStripSpaces(value: Boolean);
begin
  stripspaces:=value ;
end;

function TBasicPreprocessor.getEncoding: TEncoding;
begin
  // Кодировка по умолчанию
  Result:=TEncoding.UTF8 ;
  // Приоритет у командной строки, потом у прагмы
  if paramenc then Result:=paramenc.Value else
  if pragmaenc then Result:=pragmaenc.Value ;
end;

function TBasicPreprocessor.getErrMsg: string;
begin
  Result:=errmsg ;
end;

procedure TBasicPreprocessor.SetEncodingFromParams(value: TEncoding);
begin
  paramenc:=value ;
end;

procedure TBasicPreprocessor.SetParamsFromPairs(pairs: TStringList);
var i:Integer ;
    enc:TOptional<TEncoding> ;
begin
  for i := 0 to pairs.Count-1 do begin
    if pairs.Names[i]='codepage' then begin
      enc:=getEncodingByName(pairs.ValueFromIndex[i]) ;
      if enc then SetEncodingFromParams(enc.Value) else raise Exception.Create('Unknown codepage: '+pairs.ValueFromIndex[i]) ;
    end
    else
    if pairs.Names[i]='autonumlines' then EnableAutonumerates(pairs.ValueFromIndex[i].ToLower()='true') else
    if pairs.Names[i]='startline' then SetStartLine(StrToInt(pairs.ValueFromIndex[i])) else
    if pairs.Names[i]='stepline' then SetStepLine(StrToInt(pairs.ValueFromIndex[i])) else
    if pairs.Names[i]='define' then AddDefine(pairs.ValueFromIndex[i].ToUpper()) else
    if pairs.Names[i]='packnames' then EnablePackNames(pairs.ValueFromIndex[i].ToLower()='true') else
    if pairs.Names[i]='stripspaces' then EnableStripSpaces(pairs.ValueFromIndex[i].ToLower()='true') else
      raise Exception.Create('Unknown parameter: '+pairs.Names[i]) ;
  end;
end;

procedure TBasicPreprocessor.SetStartLine(value: Integer);
begin
  startline:=value ;
end;

procedure TBasicPreprocessor.SetStepLine(value: Integer);
begin
  stepline:=value ;
end;

function TBasicPreprocessor.GetDefineCommandFromLine(const line: string;
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

function TBasicPreprocessor.StripCommentFromLine(const line: string): string;
var i:Integer ;
    instring:Boolean ;
begin
  instring:=False ;
  for i := 0 to line.Length-1 do begin
    if line[i]='"' then instring:=not instring ;
    if not instring then
      if (line[i]='''')or (line.Substring(i,3).ToUpper()='REM') then
        Exit(line.Substring(0,i-1)) ;
  end;
  Result:=line ;
end;

procedure TBasicPreprocessor.UpdateParamsByPragmas();
var s,pragma:string ;
    lines:TStringList ;
    newenc:TOptional<TEncoding> ;
begin
  lines:=TStringList.Create() ;
  lines.LoadFromFile(inputfile,TEncoding.GetEncoding(866)) ;
  for s in lines do
    if s.Trim().ToUpper().IndexOf('''$PRAGMA:')=0 then begin
      pragma:=s.Trim().ToUpper().Replace('''$PRAGMA:','').Replace('''','').Trim() ;
      newenc:=getEncodingByName(pragma) ;
      if newenc then pragmaenc:=newenc else
      if pragma='AUTONUMLINES' then autonumlines:=True else
        raise Exception.Create('Unknown PRAGMA: '+pragma);
    end ;
  lines.Free ;
end;

function TBasicPreprocessor.LoadSourceFile(const filename: string; srcenc:TEncoding): TStringList;
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

function TBasicPreprocessor.getResult(): TOptional<TStringList>;
var i:Integer ;
    script:TStringList ;
    currentdefblock:string ;
    currentdefblockstate:TDefBlockState ;
begin
  try
  UpdateParamsByPragmas() ;

  // Загрузка файла с учетом включаемых файлов
  script:=loadSourceFile(inputfile,getEncoding()) ;

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

  if autonumlines then
    with TLineNumerator.Create(script,startline,stepline) do begin
      script.Free ;
      script:=getNumeratedLines() ;
      Free ;
    end;

  // Обязательно после автонумерации
  if packnames then
    with TNamePacker.Create(script) do begin
      script.Free ;
      script:=getPackedLines() ;
      Free ;
    end;

  // Обязательно после автонумерации и после упаковки символов
  if stripspaces then
    with TSpaceStripper.Create(script) do begin
      script.Free ;
      script:=getStrippedLines() ;
      Free ;
    end;

  Result:=script ;
  except
    on E:Exception do begin
      errmsg:=E.message ;
      Exit(TOptional<TStringList>.NullOptional) ;
    end ;
  end;
end;

end.
