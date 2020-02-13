<%@ Page LANGUAGE="VB" CodePage="65001" ASPCompat="true" %>
<%@ import namespace="BosBase" %>
<%@ import namespace="BOSG" %>
<%@ import namespace="BOSL" %>
<%
	If checkLogin() <> "" Then
		Response.Write ("-1")
		Response.End
	End If
    Dim Conn As ADODB.Connection
    Dim RS As New ADODB.Recordset
    OpenDB(Conn)
    RS.ActiveConnection=Conn
	
	Dim WSselectStr As String 
	Dim k,WshiftCnt As Integer
	Dim prevWDate, wDateDOnly As Long
	
	RS.Open(SQLTOP("Select Top 200 WShift.I, WShift.C, WShift.Ca, WShift.WDate, WShift.WStatus, Staff.N From WShift Inner Join Staff On WMan=Staff.I Where POS=" & Session("U_POS") & " Order By WDate Desc, C Desc"))
	WSselectStr = "<table cellspacing=0 cellpadding=4 style='margin-top:6px;background:black;border:2px solid #000;border-radius:8px;font-size:13px;color:#999'>"
	k = 0
	While Not RS.EOF
		WshiftCnt += 1
		WSselectStr &= "<tr"
		wDateDOnly = RS("WDate").Value - RS("WDate").Value Mod 86400
		If prevWDate <> wDateDOnly Then
			k += 1
			prevWDate = wDateDOnly
		End If
		If k Mod 2 = 0 Then
			WSselectStr &= " bgcolor='#222233'"
		End If
		Select Case RS("WStatus").Value
			Case 0
				WSselectStr &= " style='color:green;font-weight:bold'"
			Case 7
				WSselectStr &= " style='color:#999'"
		End Select
		WSselectStr &= "><td>" & WshiftCnt & "<td><a href=""javascript:setWShift(" & RS(0).Value & ", " & IIf(RS("WStatus").Value <> 0, "true", "false") & ", '" & DateShortVN(RS("WDate").Value) & " - ca " & RS("Ca").Value & "')"">" & RS("C").Value & " (" & DateTimeShortVN(RS("WDate").Value) & ") <td>Ca " & RS("Ca").Value & " - " & RS("N").Value & "</a>"
		RS.MoveNext()
	End While
	RS.Close()
	WSselectStr &= "</table>"

	If WshiftCnt > 1 Then
		Response.Write("<table width='100%'><tr><td><b>Chọn một trong các ca dưới đây:</b></td><td align='right'><img class='imggo' src='../Img/CloseW.gif' onclick='s3wsviewclose();' title=''/></td></tr></table>")
		Response.Write(WSselectStr)
	Else
		Response.Write("<img src='../img/stop.Gif'> Chưa có dữ liệu ca trong hệ thống!")
	End If

	Response.Write("<script language='javascript'>g_tag('S3PCEstatus').style.display='none';</script>")

    RS =Nothing
    CloseDB(Conn)
%>
