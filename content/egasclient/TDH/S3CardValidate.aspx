<%@ Page LANGUAGE="VB" CodePage="65001" ASPCompat="true" validateRequest="False"%>
<%@ Import namespace="System.IO" %>
<%@ Import namespace="System.Net" %>
<%@ import namespace="BOSBase.BUtils" %>

<%

Dim cardstr = Request.Form.Item("ct")
Dim cardnumber As String
Dim errCode As Integer

If Request.Form.Item("manual")="on" Then
	cardnumber = Replace$(cardstr, " ", "")
Else
	Dim i1, i2, i3 As Integer
	i1 = Instr(cardstr, "¿º")
	i2 = Instr(cardstr, "»")

	Dim number2 As String

	If i1>0 And i2>0 Then
		cardnumber = Mid$(cardstr,3,i1-3)
		number2 = Mid$(cardstr,3,i2-i1-2)

		If cardnumber <> number2 Then
			Response.Write ("<font color='red'>Lỗi đọc số thẻ (số đối chiếu không đúng)</font>")
			ErrCode = -1
		End If
	Else
		Response.Write ("<font color='red'>Lỗi đọc số thẻ (format error)</font>")
		ErrCode = -2
	End If
End If

If Not isNumeric(cardnumber) Then
	Response.Write ("<font color='red'>Lỗi số thẻ (chỉ dùng số, không dùng ký tự chữ)</font>")
	ErrCode = 9
End If

If errCode<>0 Then
	Response.End
End If

'// Check directly from server
Try
	Dim http As WebRequest = WebRequest.Create("https://egas.petrolimex.com.vn/TDH/S3CardValidateProxy.aspx")
	Dim byteArray As Byte() = Encoding.UTF8.GetBytes("compidproxy=" & TBTEncrypt(Session("U_Company")) & "&cardno=" & TBTEncrypt(CardNumber))
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
	
	Response.Clear()
	Response.Write(resultFromServer)
	http=Nothing
	http2=Nothing
Catch httpExp As Exception
	Response.Write(CardNumber & "/S: [EGAS Server Timed out!]")
	'Response.Write (httpExp.ToString())
End Try
%>