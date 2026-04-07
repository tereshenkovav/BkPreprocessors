unit BasicPreprocessor ;

interface
uses Classes, SysUtils, Optional, AbstractPreprocessor ;

type
  TBasicPreprocessor = class(TAbstractPreprocessor)
  private
    autonumlines:Boolean ;
    stripspaces:Boolean ;
    startline,stepline:Integer ;
  protected
    function SetParamFromPair(const name:string; const value:string):Boolean ; override ;
    function SetPragma(const name:string):Boolean; override ;
    function StripCommentFromLine(const line:string):string ; override ;
    function GetDefineCommandFromLine(const line: string; var defname: string): TDefBlockCommand; override ;
    function isIncludeDirective(const line:string; var incfile:string):Boolean ; override ;
    function isPragmaDirective(const line:string; var pragma:string):Boolean ; override ;
  public
    constructor Create(const Ainputfile:string) ;
    function getResult():TOptional<TStringList> ;
  end;

implementation
uses SourceEncodings, LineNumerator, NamePacker, SpaceStripper ;

{ TBasicPreprocessor }

constructor TBasicPreprocessor.Create(const Ainputfile: string);
begin
  inherited Create(Ainputfile) ;
  autonumlines:=False ;
  startline:=10 ;
  stepline:=10 ;
end;

// Переопределения настроек конкретного препроцессора

function TBasicPreprocessor.isIncludeDirective(const line: string;
  var incfile: string): Boolean;
begin
  Result:=False ;
  if line.Trim().IndexOf('''$INCLUDE:')=0 then begin
    incfile:=line.Replace('''$INCLUDE:','').Replace('''','').Trim() ;
    Result:=True ;
  end;
end;

function TBasicPreprocessor.isPragmaDirective(const line: string;
  var pragma: string): Boolean;
begin
  Result:=False ;
  if line.Trim().ToUpper().IndexOf('''$PRAGMA:')=0 then begin
    pragma:=line.Trim().ToUpper().Replace('''$PRAGMA:','').Replace('''','').Trim() ;
    Result:=True ;
  end;
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

function TBasicPreprocessor.SetParamFromPair(const name, value: string): Boolean;
begin
  Result:=True ;
  if name='autonumlines' then autonumlines:=value.ToLower()='true' else
  if name='startline' then startline:=StrToInt(value) else
  if name='stepline' then stepline:=StrToInt(value) else
  if name='stripspaces' then stripspaces:=value.ToLower()='true' else
  Result:=False ;
end;

function TBasicPreprocessor.SetPragma(const name: string): Boolean;
begin
  Result:=True ;
  if name='AUTONUMLINES' then autonumlines:=True else
  Result:=False ;
end;

function TBasicPreprocessor.StripCommentFromLine(const line: string): string;
var i:Integer ;
    instring:Boolean ;
begin
  instring:=False ;
  for i := 1 to line.Length do begin
    if line[i]='"' then instring:=not instring ;
    if not instring then
      if (line[i]='''')or (line.Substring(i-1,3).ToUpper()='REM') then
        Exit(line.Substring(0,i-1)) ;
  end;
  Result:=line ;
end;

// Функция основной работы
function TBasicPreprocessor.getResult(): TOptional<TStringList>;
var script:TStringList ;
begin
  try
  UpdateParamsByPragmas() ;

  // Загрузка файла с учетом включаемых файлов
  script:=loadSourceFile(inputfile,getEncoding()) ;

  // Обработка условных директив и удаление комментариев
  ProcessPragmasAndComments(script) ;

  if autonumlines then
    with TLineNumerator.Create(script,startline,stepline) do begin
      script.Free ;
      script:=getNumeratedLines() ;
      Free ;
    end;

  // Обязательно после автонумерации
  if packnames then
    with TNamePacker.Create(script,BASIC_NAME_ALIASES) do begin
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
