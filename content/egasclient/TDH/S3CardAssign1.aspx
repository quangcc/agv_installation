<%@ Page LANGUAGE="VB" CodePage="65001" ASPCompat="true"%>
<%@ import namespace="BOSL" %>
<%@ import namespace="BOSG" %>

<%

If checkLogin() <> "" Then
	Response.Write ("LOGIN EXPIRED!")
	Response.End
End If

Dim Conn As ADODB.Connection
Dim RS As New ADODB.RecordSet
OpenDB(Conn)
RS.ActiveConnection = Conn

'// Discount Card Processing
Dim cardNoPars() As String
Dim disSQL As String
Dim disAmt As Double = 0
Dim product As Long

Dim S3LogI As Long = Request.Form.Item("logI")

RS.Open("Select ProductI From S3Log Where I=" & S3LogI)
product = RS(0).Value
RS.Close

cardNoPars = Split$(Request.Form.Item("cardno"), "/")
disSQL = "Select DIS From S3CardDiscount Where P=" & product & " And cardType='" & cardNoPars(1) & "' And " & SQLGetDate() & ">=validFrom[=POS] Order By validFrom Desc"
RS.Open(Replace$(disSQL, "[=POS]", " And POS=" & Session("U_POS")))
If RS.EOF Then
	RS.Close
	RS.Open(Replace$(disSQL, "[=POS]", ""))
End If
If Not RS.EOF Then
	DisAmt = CdblNull(RS(0).Value)
End If
RS.Close

'//SQLExec(RS, "Update S3Log Set CardNumber=" & cardNoPars(0) & ",Discount=" & DisAmt & " Where I=" & S3LogI, True, "", "", "S3Log", -1, "U")
Dim str As String = ""
	str &= Request.Form.Item("pumptt") & ",>"
	str &= Request.Form.Item("pumpid") & ",>"
	str &= Request.Form.Item("logI") & ",>"
	str &= Request.Form.Item("payI") & ",>"
	str &= Request.Form.Item("jobst") & ",>"
	str &= cardNoPars(0) & ",>"
	str &= DisAmt & ",>"
	str &= Request.Form.Item("linenumber")
Response.Write(str)

RS=Nothing
CloseDB(Conn)
%>