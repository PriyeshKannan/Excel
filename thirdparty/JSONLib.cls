VERSION 1.0 CLASS
BEGIN
  MultiUse = -1  'True
END
Attribute VB_Name = "JSONLib"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = False
Attribute VB_Exposed = False
'------------------------------------------------------------------------------------
'Soure:https://code.google.com/p/vba-json/
'http://opensource.org/licenses/BSD-3-Clause
'------------------------------------------------------------------------------------
Option Explicit

Const INVALID_JSON      As Long = 1
Const INVALID_OBJECT    As Long = 2
Const INVALID_ARRAY     As Long = 3
Const INVALID_BOOLEAN   As Long = 4
Const INVALID_NULL      As Long = 5
Const INVALID_KEY       As Long = 6

'
'   parse string and create JSON object (Dictionary or Collection in VB)
'
Public Function parse(ByRef str As String) As Object

    Dim Index As Long
    Index = 1
    
    On Error Resume Next

    Call skipChar(str, Index)
    Select Case mid(str, Index, 1)
    Case "{"
        Set parse = parseObject(str, Index)
    Case "["
        Set parse = parseArray(str, Index)
    End Select

End Function

'
'   parse collection of key/value (Dictionary in VB)
'
Private Function parseObject(ByRef str As String, ByRef Index As Long) As Object

    Set parseObject = CreateObject("Scripting.Dictionary")
    
    ' "{"
    Call skipChar(str, Index)
    If mid(str, Index, 1) <> "{" Then Err.Raise vbObjectError + INVALID_OBJECT, Description:="char " & Index & " : " & mid(str, Index)
    Index = Index + 1
    
    Do
    
        Call skipChar(str, Index)
        If "}" = mid(str, Index, 1) Then
            Index = Index + 1
            Exit Do
        ElseIf "," = mid(str, Index, 1) Then
            Index = Index + 1
            Call skipChar(str, Index)
        End If
        
        Dim key As String
        
        ' add key/value pair
        parseObject.Add key:=parseKey(str, Index), Item:=parseValue(str, Index)
        
    Loop

End Function

'
'   parse list (Collection in VB)
'
Private Function parseArray(ByRef str As String, ByRef Index As Long) As Collection

    Set parseArray = New Collection
    
    ' "["
    Call skipChar(str, Index)
    If mid(str, Index, 1) <> "[" Then Err.Raise vbObjectError + INVALID_ARRAY, Description:="char " & Index & " : " + mid(str, Index)
    Index = Index + 1
    
    Do
        
        Call skipChar(str, Index)
        If "]" = mid(str, Index, 1) Then
            Index = Index + 1
            Exit Do
        ElseIf "," = mid(str, Index, 1) Then
            Index = Index + 1
            Call skipChar(str, Index)
        End If
        
        ' add value
        parseArray.Add parseValue(str, Index)
        
    Loop

End Function

'
'   parse string / number / object / array / true / false / null
'
Private Function parseValue(ByRef str As String, ByRef Index As Long)

    Call skipChar(str, Index)
    
    Select Case mid(str, Index, 1)
    Case "{"
        Set parseValue = parseObject(str, Index)
    Case "["
        Set parseValue = parseArray(str, Index)
    Case """", "'"
        parseValue = parseString(str, Index)
    Case "t", "f"
        parseValue = parseBoolean(str, Index)
    Case "n"
        parseValue = parseNull(str, Index)
    Case Else
        parseValue = parseNumber(str, Index)
    End Select

End Function

'
'   parse string
'
Private Function parseString(ByRef str As String, ByRef Index As Long) As String

    Dim quote   As String
    Dim char    As String
    Dim code    As String
    
    Call skipChar(str, Index)
    quote = mid(str, Index, 1)
    Index = Index + 1
    Do While Index > 0 And Index <= Len(str)
        char = mid(str, Index, 1)
        Select Case (char)
        Case "\"
            Index = Index + 1
            char = mid(str, Index, 1)
            Select Case (char)
            Case """", "\\", "/"
                parseString = parseString & char
                Index = Index + 1
            Case "b"
                parseString = parseString & vbBack
                Index = Index + 1
            Case "f"
                parseString = parseString & vbFormFeed
                Index = Index + 1
            Case "n"
                parseString = parseString & vbNewLine
                Index = Index + 1
            Case "r"
                parseString = parseString & vbCr
                Index = Index + 1
            Case "t"
                parseString = parseString & vbTab
                Index = Index + 1
            Case "u"
                Index = Index + 1
                code = mid(str, Index, 4)
                parseString = parseString & ChrW(val("&h" + code))
                Index = Index + 4
            End Select
        Case quote
            Index = Index + 1
            Exit Function
        Case Else
            parseString = parseString & char
            Index = Index + 1
        End Select
    Loop

End Function

'
'   parse number
'
Private Function parseNumber(ByRef str As String, ByRef Index As Long)

    Dim Value   As String
    Dim char    As String
    
    Call skipChar(str, Index)
    Do While Index > 0 And Index <= Len(str)
        char = mid(str, Index, 1)
        If InStr("+-0123456789.eE", char) Then
            Value = Value & char
            Index = Index + 1
        Else
            If InStr(Value, ".") Or InStr(Value, "e") Or InStr(Value, "E") Then
                parseNumber = CDbl(Value)
            Else
                parseNumber = CInt(Value)
            End If
            Exit Function
        End If
    Loop


End Function

'
'   parse true / false
'
Private Function parseBoolean(ByRef str As String, ByRef Index As Long) As Boolean

    Call skipChar(str, Index)
    If mid(str, Index, 4) = "true" Then
        parseBoolean = True
        Index = Index + 4
    ElseIf mid(str, Index, 5) = "false" Then
        parseBoolean = False
        Index = Index + 5
    Else
        Err.Raise vbObjectError + INVALID_BOOLEAN, Description:="char " & Index & " : " & mid(str, Index)
    End If

End Function

'
'   parse null
'
Private Function parseNull(ByRef str As String, ByRef Index As Long)

    Call skipChar(str, Index)
    If mid(str, Index, 4) = "null" Then
        parseNull = Null
        Index = Index + 4
    Else
        Err.Raise vbObjectError + INVALID_NULL, Description:="char " & Index & " : " & mid(str, Index)
    End If

End Function

Private Function parseKey(ByRef str As String, ByRef Index As Long) As String

    Dim dquote  As Boolean
    Dim squote  As Boolean
    Dim char    As String
    
    Call skipChar(str, Index)
    Do While Index > 0 And Index <= Len(str)
        char = mid(str, Index, 1)
        Select Case (char)
        Case """"
            dquote = Not dquote
            Index = Index + 1
            If Not dquote Then
                Call skipChar(str, Index)
                If mid(str, Index, 1) <> ":" Then
                    Err.Raise vbObjectError + INVALID_KEY, Description:="char " & Index & " : " & parseKey
                End If
            End If
        Case "'"
            squote = Not squote
            Index = Index + 1
            If Not squote Then
                Call skipChar(str, Index)
                If mid(str, Index, 1) <> ":" Then
                    Err.Raise vbObjectError + INVALID_KEY, Description:="char " & Index & " : " & parseKey
                End If
            End If
        Case ":"
            If Not dquote And Not squote Then
                Index = Index + 1
                Exit Do
            End If
        Case Else
            If InStr(vbCrLf & vbCr & vbLf & vbTab & " ", char) Then
            Else
                parseKey = parseKey & char
            End If
            Index = Index + 1
        End Select
    Loop

End Function

'
'   skip special character
'
Private Sub skipChar(ByRef str As String, ByRef Index As Long)

    While Index > 0 And Index <= Len(str) And InStr(vbCrLf & vbCr & vbLf & vbTab & " ", mid(str, Index, 1))
        Index = Index + 1
    Wend

End Sub

Public Function toString(ByRef obj As Variant) As String

    Select Case VarType(obj)
        Case vbNull
            toString = "null"
        Case vbDate
            toString = """" & CStr(obj) & """"
        Case vbString
            toString = """" & encode(obj) & """"
        Case vbObject
            Dim bFI, i
            bFI = True
            If TypeName(obj) = "Dictionary" Then
                toString = toString & "{"
                Dim keys
                keys = obj.keys
                For i = 0 To obj.Count - 1
                    If bFI Then bFI = False Else toString = toString & ","
                    Dim key
                    key = keys(i)
                    If Len(trim(key)) > 0 Then
                        toString = toString & """" & key & """:" & toString(obj(key))
                    End If
                Next i
                toString = toString & "}"
            ElseIf TypeName(obj) = "Collection" Then
                toString = toString & "["
                Dim Value
                For Each Value In obj
                    If bFI Then bFI = False Else toString = toString & ","
                    toString = toString & toString(Value)
                Next Value
                toString = toString & "]"
            End If
        Case vbBoolean
            If obj Then toString = "true" Else toString = "false"
        Case vbVariant, vbArray, vbArray + vbVariant
            Dim sEB
            toString = multiArray(obj, 1, "", sEB)
        Case Else
            toString = Replace(obj, ",", ".")
    End Select

End Function

Private Function encode(str) As String
    
    Dim i, j, aL1, aL2, c, p

    aL1 = Array(&H22, &H5C, &H2F, &H8, &HC, &HA, &HD, &H9)
    aL2 = Array(&H22, &H5C, &H2F, &H62, &H66, &H6E, &H72, &H74)
    For i = 1 To Len(str)
        p = True
        c = mid(str, i, 1)
        For j = 0 To 7
            If c = Chr(aL1(j)) Then
                encode = encode & "\" & Chr(aL2(j))
                p = False
                Exit For
            End If
        Next

        If p Then
            Dim a
            a = AscW(c)
            If a > 31 And a < 127 Then
                encode = encode & c
            ElseIf a > -1 Or a < 65535 Then
                encode = encode & "\u" & String(4 - Len(Hex(a)), "0") & Hex(a)
            End If
        End If
    Next
End Function

Private Function multiArray(aBD, iBC, sPS, ByRef sPT)   ' Array BoDy, Integer BaseCount, String PoSition
    Dim iDU, iDL, i ' Integer DimensionUBound, Integer DimensionLBound
    On Error Resume Next
    iDL = LBound(aBD, iBC)
    iDU = UBound(aBD, iBC)
    
    Dim sPB1, sPB2  ' String PointBuffer1, String PointBuffer2
    If Err.Number = 9 Then
        sPB1 = sPT & sPS
        For i = 1 To Len(sPB1)
            If i <> 1 Then sPB2 = sPB2 & ","
            sPB2 = sPB2 & mid(sPB1, i, 1)
        Next
'        multiArray = multiArray & toString(Eval("aBD(" & sPB2 & ")"))
        multiArray = multiArray & toString(aBD(sPB2))
    Else
        sPT = sPT & sPS
        multiArray = multiArray & "["
        For i = iDL To iDU
            Dim Temp As String
            Temp = multiArray(aBD, iBC + 1, i, sPT)
            If Len(trim(Temp)) > 0 Then
                multiArray = multiArray & Temp
                If i < iDU Then multiArray = multiArray & ","
            End If
        Next
        Dim lPosition As Integer
        Dim lenOfData As Integer
        lenOfData = Len(multiArray)
        lPosition = InStr(lenOfData, multiArray, ",")
        If lenOfData = lPosition Then
            multiArray = Left(multiArray, lPosition - 1)
        End If
        multiArray = multiArray & "]"
        sPT = Left(sPT, iBC - 2)
    End If
    Err.Clear
End Function

