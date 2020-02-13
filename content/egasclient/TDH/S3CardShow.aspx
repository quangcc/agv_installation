<%@ Page LANGUAGE="VB" CodePage="65001" ASPCompat="true"%>
<%@ Import namespace="System.IO" %>
<%@ Import namespace="System.Net" %>
<%@ import namespace="BOSBase.BUtils" %>
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

RS.Open("Select S3Log.CardNumber,S3Log.Discount From S3Log Where S3Log.I=" & Request.Form.Item("logI"))

Dim cardNumber As String = RS(0).Value
Dim discount As Double = CdblNull(RS(1).Value)
Dim customerName As String

RS.Close
RS=Nothing
CloseDB(Conn)

Try
	Dim http As WebRequest = WebRequest.Create("https://egas.petrolimex.com.vn/TDH/S3CardShowProxy.aspx")
	Dim byteArray As Byte() = Encoding.UTF8.GetBytes("compidproxy=" & TBTEncrypt(Session("U_Company")) & "&cardno=" & cardNumber)
	http.method = "POST"
	http.ContentType = "application/x-www-form-urlencoded"
	http.ContentLength = byteArray.Length
	http.Timeout = 5000 '// 5 seconds
	Dim dataStream As Stream = http.GetRequestStream()
	dataStream.Write(byteArray, 0, byteArray.Length)
	dataStream.Close()
	Dim http2 As WebResponse = http.GetResponse()
	dataStream = http2.GetResponseStream()
	Dim readerObj As New StreamReader(dataStream)
	Dim resultFromServer As String = readerObj.ReadToEnd()
	readerObj.Close()
	dataStream.Close()
	http2.Close()
	
	customerName = resultFromServer
	
	http=Nothing
	http2=Nothing
Catch httpExp As Exception
	customerName = "[EGAS Server Timed out]"
	'Response.Write (httpExp.ToString())
End Try

Response.Write(Request.Form.Item("pumptt") & ",>" & Request.Form.Item("linenumber") & ",> &nbsp; <a href='javascript:void(cardunassign(" & Request.Form.Item("logI") & "))'>Hủy</a> " & cardNumber & " - " & CustomerName & ", Dis: " & FMN(Discount,0))

%>