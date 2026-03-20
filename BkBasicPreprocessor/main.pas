unit main ;

interface
uses SysUtils, Classes ;

type
  TDefBlockState = (dbsNone,dbsThen,dbsElse) ;
  TDefBlockCommand = (dbcNone,dbcDefine,dbcElse,dbcEnd) ;

  TMain = class
  private
    srcenc:TEncoding ;
    autonumlines:Boolean ;
    function StripCommentFromLine(const line:string):string ;
    function GetDefineCommandFromLine(const line:string; var defname:string):TDefBlockCommand ;
    procedure ExitWithError(const msg: string; code: Integer);
    function LoadSourceFile(const filename:string):TStringList ;
    procedure UpdateParamsByPragmasFromSourceFile(const filename:string) ;
  public
    procedure Run() ;
  end;

implementation
uses Generics.Collections, Math, LineNumerator, Optional, Version ;

const MAINHELP = 'Preprocessor for BK-0010 Basic'#13#10+
  'Version: '+TGitVersion.TAG+#13#10+
  'Usage: input_file output_file [parameters]'#13#10+
  'Parameters:'#13#10+
  '/codepage=utf8|win1251|koi8r|oem866 - Basic file codepage'#13#10+
  '/autonumlines=true|false - set line numbers to non-numbered Basic source'#13#10+
  '/define=name - set name for ''$IFDEF directive' ;

procedure TMain.ExitWithError(const msg: string; code: Integer);
begin
  Writeln(msg) ;
  Halt(code) ;
end;

function TMain.GetDefineCommandFromLine(const line: string;
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

function TMain.LoadSourceFile(const filename: string): TStringList;
var i:Integer ;
    j:Integer ;
    incfile:string ;
    included:TStringList ;
begin
  Result:=TStringList.Create() ;
  Result.LoadFromFile(filename,srcenc) ;
  i:=0 ;
  while i<Result.Count do begin
    if Result[i].Trim().IndexOf('''$INCLUDE:')=0 then begin
      incfile:=Result[i].Replace('''$INCLUDE:','').Replace('''','').Trim() ;
      if not FileExists(incfile) then ExitWithError('Not found included file: '+incfile,1) ;
      Result.Delete(i) ;
      included:=LoadSourceFile(incfile) ;
      for j:=0 to included.Count-1 do
        Result.Insert(i+j,included[j]) ;
      included.Free ;
    end
    else
      Inc(i) ;
  end ;

end;

procedure TMain.Run() ;
var script:TStringList ;
    pname,pvalue:string ;
    i,p:Integer ;
    destfile:string ;
    ln:TLineNumerator ;
    newlines:TOptional<TStringList> ;
    deflist:TStringList ;
    currentdefblock:string ;
    currentdefblockstate:TDefBlockState ;
begin
  try
    if ParamCount<1 then ExitWithError(MAINHELP,1) ;

    deflist:=TStringList.Create ;
    srcenc:=TEncoding.UTF8 ;
    autonumlines:=False ;

    // Прагмы проверяем в начале, потому что у аргументов командной строки - приоритет
    UpdateParamsByPragmasFromSourceFile(ParamStr(1)) ;

    for i := 3 to ParamCount do begin
      if ParamStr(i)[1]<>'/' then ExitWithError('Unknown argument: '+ParamStr(i)+', use /name=value',2) ;
      p:=ParamStr(i).IndexOf('=') ;
      if p=-1 then ExitWithError('Unknown argument: '+ParamStr(i)+', use /name=value',3) ;
      pname:=ParamStr(i).Substring(1,p-1) ;
      pvalue:=ParamStr(i).Substring(p+1).ToLower() ;
      if pname='codepage' then begin
        if (pvalue<>'utf8') and (pvalue<>'win1251') and
           (pvalue<>'koi8r') and (pvalue<>'oem866')  then
          ExitWithError('Unknown codepage: '+pvalue,4) ;
        if pvalue='win1251' then srcenc:=TEncoding.GetEncoding(1251) ;
        if pvalue='oem866' then srcenc:=TEncoding.GetEncoding(866) ;
        if pvalue='koi8r' then srcenc:=TEncoding.GetEncoding(20866) ;
      end
      else
      if pname='autonumlines' then autonumlines:=pvalue='true'
      else
      if pname='define' then deflist.Add(pvalue.ToUpper())
      else
        ExitWithError('Unknown parameter: '+pname,5) ;
    end;

    if not FileExists(ParamStr(1)) then
      ExitWithError('Not found input file: '+ParamStr(1),6) ;

    destfile:=ParamStr(2) ;

    // Загрузка файла с учетом включаемых файлов
    script:=loadSourceFile(ParamStr(1)) ;

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
            ExitWithError('Multilevel $IFDEF not supported yet',1) ;
        dbcElse:
          if currentdefblockstate=dbsThen then
            currentdefblockstate:=dbsElse
          else
            ExitWithError('$ELSE without $IFDEF',1) ;
        dbcEnd:
          if currentdefblockstate in [dbsThen,dbsElse] then
            currentdefblockstate:=dbsNone
          else
            ExitWithError('$ENDIF without $ELSE or $IDFEF',1) ;
      end;
      script[i]:=StripCommentFromLine(script[i]).Trim() ;
      if script[i].Length=0 then script.Delete(i) else
      if (currentdefblockstate=dbsThen)and
        (deflist.IndexOf(currentdefblock)=-1) then script.Delete(i) else
      if (currentdefblockstate=dbsElse)and
        (deflist.IndexOf(currentdefblock)<>-1) then script.Delete(i) else
         Inc(i) ;
    end;

    if autonumlines then begin
      ln:=TLineNumerator.Create(script) ;
      newlines:=ln.getNumeratedLines() ;
      if (newlines) then begin
        script.Free ;
        script:=newlines.Value ;
      end
      else
        ExitWithError('Error enumerate lines: '+ln.getErrMsg(),10) ;
      ln.Free ;
    end;

    script.SaveToFile(ParamStr(2),srcenc) ;
    script.Free ;

    deflist.Free ;
  except
    on E: Exception do
      Writeln('Error '+E.ClassName+': '+E.Message);
  end;
end ;

function TMain.StripCommentFromLine(const line: string): string;
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

procedure TMain.UpdateParamsByPragmasFromSourceFile(const filename: string);
var s,pragma:string ;
    lines:TStringList ;
begin
  lines:=TStringList.Create() ;
  lines.LoadFromFile(filename,TEncoding.GetEncoding(866)) ;
  for s in lines do
    if s.Trim().ToUpper().IndexOf('''$PRAGMA:')=0 then begin
      pragma:=s.Trim().ToUpper().Replace('''$PRAGMA:','').Replace('''','').Trim() ;
      if pragma='UTF8' then srcenc:=TEncoding.UTF8 ;
      if pragma='WIN1251' then srcenc:=TEncoding.GetEncoding(1251) ;
      if pragma='OEM866' then srcenc:=TEncoding.GetEncoding(866) ;
      if pragma='KOI8R' then srcenc:=TEncoding.GetEncoding(20866) ;
      if pragma='AUTONUMLINES' then autonumlines:=True ;
    end ;
  lines.Free ;
end;

end.
