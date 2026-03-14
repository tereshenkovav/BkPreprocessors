# Примеры обработки исходных кодов Бейсика препроцессором

## Обработка комментариев, пустых строк и меток

Исходный файл:
``` BASIC
' Просто комментарий в UTF-8
PRINT "Basic program with auto line nums"

' Блоки со ссылками для тестирования
LabData: DATA 1,2,3
Label1: PRINT "Line with LABEL1"
LABEL2: PRINT "Line with LABEL2"
LaBeL3: PRINT "Line with LABEL3"
label4: PRINT "Line with LABEL4"

' Использование ссылок во всех конструкциях
RESTORE LabData
GOTO  Label1
GOSUB Label2
ON I% GOSUB LABEL1,label2
ON I% GOTO LABEL3, label4
IF I%=1 THEN GOTO Label1   ELSE  GOSUB LABEL4

' Конец программы и пара пустых строк


END
```

Обработанный файл:
``` BASIC
10 PRINT "Basic program with auto line nums"
20 DATA 1,2,3
30 PRINT "Line with LABEL1"
40 PRINT "Line with LABEL2"
50 PRINT "Line with LABEL3"
60 PRINT "Line with LABEL4"
70 RESTORE 20
80 GOTO 30
90 GOSUB 40
100 ON I% GOSUB 30,40
110 ON I% GOTO 50,60
120 IF I%=1 THEN GOTO 30 ELSE  GOSUB 60
130 END
```

## Пример использования условных директив вместе с автонумерацией

Исходный файл:
``` BASIC
'$IFDEF BK10
PRINT "BK10 is defined"
'$ENDIF

'$IFDEF BK11
PRINT "BK11 is defined"
'$ELSE
PRINT "BK11 is not defined"
'$ENDIF
```
Обработанный файл при передаче в аргументах команды /define=BK10
``` BASIC
10 PRINT "BK10 is defined"
20 PRINT "BK11 is not defined"
```

## Пример использования прагм кодировки и автонумерации

Исходный файл:
``` BASIC
'$PRAGMA: WIN1251
'$PRAGMA: AUTONUMLINES
PRINT "Текст в кодировке Win1251"
BEEP
END
```
Подготовленный файл для сохранения в цепочку ASC-файлов

``` BASIC
10 PRINT "Текст в кодировке Win1251"
20 BEEP
30 END
```

## Пример использования включаемых файлов вместе с автонумерацией

Исходный файл:
``` BASIC
PRINT "Test included file"
'$INCLUDE: 'beep3.bi'
PRINT "Test OK"
```

Включаемый файл beep3.bi:
``` BASIC
BEEP
BEEP
BEEP
```

Обработанный файл:
``` BASIC
10 PRINT "Test included file"
20 BEEP
30 BEEP
40 BEEP
50 PRINT "Test OK"
```
